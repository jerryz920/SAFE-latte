package safe.safelang

import akka.actor.{ActorRef, ActorSystem}

import scala.collection.mutable.{Set => MutableSet}
import scala.collection.mutable.{Map => MutableMap}
import scala.collection.mutable.{LinkedHashSet => OrderedSet}
import setcache.SetCache
import safe.cache.SafeTable
import safesets._
import model.Principal
import safe.safelog.SafelogException.printLabel
import safe.safelog._
import util.KeyPairManager

// for expandPathname should be in some utils somewhere
import safe.safelog.Repl._

class AKeyPairManager extends KeyPairManager {}

class Repl(
  val safeSetsClient: SafeSetsClient,
  self: String, saysOperator: Boolean, 
  val slangCallClient: SlangRemoteCallClient, 
  val localSetTable: SafeTable[SetId, SlogSet], val setCache: SetCache, val contextCache: ContextCache,
  val safelangId: Int,
  val kpm: AKeyPairManager
) extends safe.safelog.Repl(self, saysOperator) with SafelangService {

  stdPromptMsg = "slang> "
  //override val greet = s"Safe Language v0.1: $date (To quit, press Ctrl+D or q.)"
  override val greet = "Welcome to\n" +
    safeBanner +
    s"Safe Language v0.1: $date (To quit, press Ctrl+D or q.)"

  override def updatePromptSelf(): Unit = {
    val sls = StrLit("Self")
    if (envContext.contains(sls)) {
      val currentSelf = envContext(sls)
      //
      // Chase 6/10/19: a little bit of Scala magic to find another variable whose
      // value is the $Self principalID.  If so, use that variable name on the prompt
      // (e.g., "Alice") instead of the raw principalID.
      //
      val s = envContext.find({ case (k, v) => (v == currentSelf && k != sls) })
      match {
        case None => currentSelf.asInstanceOf[Constant].id.name
        case Some((k, v)) => k.name
      }
      stdPromptMsg = s + "@slang> "
    } else {
      stdPromptMsg = "slang> "
    }
  }

  //
  // Chase 6/24/19
  // Upcall from slog repl for unabsorbed facts.  In slog, facts are saved in shell context for later
  // evaluation.  In slang they are commands to execute.  Execute them!
  //
  override def processFact(cmd: Term): Boolean = {
    logger.info("execute unabsorbed fact")
    try {
      val subcontexts = Seq(contextCache.get(Token("_object")).get) // _object has been populated
      val result = solveAQuery(Query(Seq(cmd)))(envContext, subcontexts)
      printLabel('info)
      println(s"${result.head}")
    } catch {
      case ex: Throwable =>
        printLabel('failure)
        println(ex.toString)
    }
    true
  }

  override def importProgram(pathname: String): SafeProgram = {
    compileSlang(pathname)
  }

  //
  // Chase 6/27/19.  Make sure all self variables match $Self, if we can.
  // Why?  Because $Self may have changed, e.g., by slang-shell command.
  // safe-server has other mechanisms to track them together, but we can't use those for Repl.
  // This is an upcall from InferenceImpl.
  // This code illustrates the mess resulting from StrLit and support for envValue other than String.
  //
  override def harmonizeSelf(ecxt: MutableMap[StrLit, EnvValue]): Unit = {
    ecxt.get(StrLit("Self")) match {
      case Some(c: Constant) =>
        kpm.getPrincipal(c.id.name) match {
          case Some(p: Principal) =>
            logger.info(s"harmonize self for matched principal ${c.id.name}")
            ecxt.put(StrLit("Selfie"), p)
            ecxt.put(StrLit("SelfKey"), Constant(StrLit(s"${p.fullPublicKey}"), StrLit("nil"), StrLit("StrLit"), Encoding.AttrBase64))
            if (c.id.name != p.pid) {
              ecxt.put(StrLit("Self"), Constant(p.pid))
              logger.info(s"harmonize: patched Self ${c.id.name} with pid ${p.pid}")
            }
          case None =>
            logger.info("no principal found for self (no action taken)")
        }
      case None =>
        logger.info("Self is not yet defined (no action taken)")
      case _ =>
        logger.error("unexpected type for Self (no action taken)")
    }
  }
}

object Repl {

import akka.util.Timeout
import com.typesafe.config.ConfigFactory
import java.util.concurrent.TimeUnit
import scala.concurrent.duration._

def main(args: Array[String]): Unit = {

 val usage = """
   Usage: Repl [--port|-p number] [--file|-f fileName] [--numWorkers|-n number] [--args|-a fileArguments] [--help|-h]
 """

 val optionalArgs = Map(
     "--port"       -> 'port
   , "-p"           -> 'port
   , "--file"       -> 'file
   , "-f"           -> 'file
   , "--args"       -> 'fileArgs
   , "-a"           -> 'fileArgs
   , "--numWorkers" -> 'numWorkers
   , "-n"           -> 'numWorkers
   , "-kd"           -> 'keyDir         // Directory of key pairs
   , "--keyDir"      -> 'keyDir
   , "--help"       -> 'help
   , "-h"           -> 'help
 )

 val argMap = safe.safelog.Util.readCmdLine(
     args.toSeq
   , requiredArgs = Nil
   , optionalArgs
   , Map('help -> "false", 'port -> "4001", 'numWorkers -> "2", 'keyDir -> Config.config.keyPairDir)
 )

 if(argMap('help) == "true") {
   println(usage)
 } else {

   val port: Int = argMap('port).toInt
   val numWorkers: Int = argMap('numWorkers).toInt

   val conf = ConfigFactory.parseString(s"akka.remote.netty.tcp.port=${port}")
.withFallback(ConfigFactory.load())

   //val shutdownGracefully: Boolean = conf.getBoolean("safe.safelang.system.shutdownGracefully")
   val shutdownGracefully: Boolean = true
    //val storeURI                = conf.getString("safe.safesets.storeURI")
   //val requestTimeout          = Timeout(conf.getDuration("safe.service.requestTimeout", TimeUnit.SECONDS), TimeUnit.SECONDS)
   val requestTimeout: FiniteDuration          = FiniteDuration(conf.getDuration("safe.safesets.requestTimeout", TimeUnit.SECONDS), TimeUnit.SECONDS)

   /*
    * Just like SafelangManager (used in safe-server), but we can't use SafelangManager here
    * because we don't *necessarily* have a keypairDir, and because a Repl inherits all the solver APIs via traits
    * and is upcalled from Slog to solve Slang via overridden methods....
    */
   val localSetTable: SafeTable[SetId, SlogSet] = new SafeTable[SetId, SlogSet](
     1024 * 1024,
     0.75f,
     16
   )
   val system: ActorSystem = ActorSystem("Safelang")
   val slangCallClient = new SlangRemoteCallClient(system)
   val safeSetsClient: SafeSetsClient = new SafeSetsClient(system)

   val setCache: SetCache = new SetCache(localSetTable, safeSetsClient)
   val contextCache: ContextCache = new ContextCache(setCache)

   val safelangId: Int = 0

   /*
    * Chase 6/27/19
    * Set up principal maps if we have a keypairdir.
    */
   val kpm = new AKeyPairManager()
   argMap('keyDir) match {
     case dirname => kpm.loadPrincipals(expandPathname(dirname))
     case _ =>
   }
/*
   val nameToID = MutableMap[String, String]()
   val principalsTable: Option[MutableMap[String, Principal]] = argMap('keyDir) match {
     case dirname => Some(kpm.loadKeyPairs(expandPathname(dirname), nameToID))
     case _ => None
   }
   inference.principalsTable = principalsTable
*/

   val inference = new Repl(safeSetsClient, Config.config.self, Config.config.saysOperator, slangCallClient, localSetTable, setCache, contextCache, safelangId, kpm)

   try {
     (argMap.get('file), argMap.get('fileArgs)) match {
       case (None, None)     => inference.repl() // The init call
       case (Some(sf), None) => inference.printOutput(inference.evalFileWithTime(sf, 'ms)) // Evaluate expressions from a file.
       case (Some(sf), Some(args)) =>
         val argSeq = args.split(",").toSeq
         var _fileContents = scala.io.Source.fromFile(sf).mkString
         argSeq.zipWithIndex.foreach{ case (arg, idx) =>
           _fileContents = _fileContents.replaceAll(s"\\$$${idx + 1}", s"'$arg'")
         }
         // write to a temp file // TODO: fix this
         import java.nio.file.{Paths, Files}
         import java.nio.charset.StandardCharsets
         //val tmpFileName = s"/tmp/$sf" //TODO: extract fileName from path
         val tmpFileName = s"/tmp/${java.util.UUID.randomUUID()}"
         Files.write(Paths.get(tmpFileName), _fileContents.getBytes(StandardCharsets.UTF_8))

         inference.printOutput(inference.evalFileWithTime(tmpFileName, 'ms)) // Evaluate expressions from a file.
       case (None, Some(args)) => //ignore args or throw an exception?
     }
   } catch {
     case err: Throwable =>
       //println(err)
       err.printStackTrace()
       gracefulShutdown(system)
   }
   if(shutdownGracefully) gracefulShutdown(system)
 }
}

def gracefulShutdown(system: ActorSystem, prompt: Boolean = false): Unit = {
 if(!prompt) {
   system.shutdown()
   sys.addShutdownHook(system.shutdown())
 } else {
   // Allow an operator to shutdown the service gracefully
   val terminate: Boolean = {
def loop(): Boolean = scala.io.StdIn.readLine() match {
 case s if s.toLowerCase.matches("""^[y\n](es)?""") => true
 case _ => println(s"terminate? [y(es)?]"); loop()
}
loop()
   }
   if(terminate) system.shutdown()

   /**
    * Ensure that the constructed ActorSystem is shut down when the JVM shuts down
    */
   sys.addShutdownHook(system.shutdown())
 }
}
}
