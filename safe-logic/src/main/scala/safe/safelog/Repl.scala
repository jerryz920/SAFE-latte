package safe.safelog


import java.nio.file.{Path, Paths}
import java.io.{File, PrintWriter}

import scala.collection.JavaConversions._
import scala.collection.mutable.{Set => MutableSet}
import scala.collection.mutable.{LinkedHashSet => OrderedSet}
import scala.util.{Try, Success, Failure}

import com.github.lalyos.jfiglet.FigletFont;

import SafelogException.printLabel

class Repl(
    self: String
  , saysOperator: Boolean
) extends Safelog(self, saysOperator) { // class is useful for unit testing and for modularity (i.e., extending from slang)

  var stdPromptMsg = "slog> "
  val date = new java.text.SimpleDateFormat("EEE, d MMM yyyy HH:mm:ss z").format(java.util.Calendar.getInstance().getTime())
  val safeBanner = FigletFont.convertOneLine("SAFE")
  val greet = "Welcome to\n" +
              safeBanner +
              s"Safe Logic v0.1: $date (To quit, press Ctrl+D or q.)"

  private val _assertionsInMemory: MutableSet[Statement] = MutableSet.empty       // Parsed assertions, for console functions
  private val _queriesInMemory: MutableSet[Statement] = MutableSet.empty          // Parsed queries
  private val _retractionsInMemory: MutableSet[Retraction] = MutableSet.empty     // Parsed retractions
  private val _queriesInMemoryFresh: MutableSet[Statement] = MutableSet.empty     // Parsed queries which are fresh, i.e., not executed yet
  private var _inputScanned: StringBuilder = new StringBuilder()  // Stores incomplete statements that end with other than (.|?|~)
  private val _replStatements = new MutableCache[Index, OrderedSet[Statement]]()  // All statements, for inference

  private val replCmdSeq = Seq(
      "clear."
    , "help."
    , "import(<file>)."
    , "ls."
    , "ls(facts)."
    , "ls(rules)."
    , "ls(queries)."
    , "ls(retractions)."
    , "ls(all)."
    , "quit."
  )

  /**
   * addStatementToRepl adds statements parsed from a program into the cache of repl statements
   */
  private def addStatementsToRepl(stmts: Map[Index, OrderedSet[Statement]]): Map[Index, OrderedSet[Statement]] = {
    stmts.keySet.foreach { idx =>
      _replStatements.get(idx) match {
        case Some(stmtSet: OrderedSet[Statement]) =>
          stmtSet ++= stmts(idx)
        case _ =>
          val newSet = OrderedSet.empty[Statement]
          newSet ++= stmts(idx)
          _replStatements.put(idx, newSet)
      }
    }
    _replStatements.toMap
  }

  private def addStatementsToRepl(stmts: MutableCache[Index, OrderedSet[Statement]]): Map[Index, OrderedSet[Statement]] = {
     addStatementsToRepl(stmts.toMap)
  }

  // [[http://jline.github.io/jline2/apidocs/reference/jline/console/ConsoleReader.html]]
  private def consoleReader(fileName: Option[String]): jline.console.ConsoleReader = {
    import java.io.File
    import scala.collection.JavaConverters._
    import scala.io.Source
    import jline.console.completer.StringsCompleter
    import jline.console.history.FileHistory

    fileName match {
      case Some(fn) => // console reader backed by a specified history file
        val file = Term.stripQuotes(fn)
        try {
          val fStream = this.getClass().getClassLoader().getResourceAsStream(file) match { // for externalized resources
            case null => this.getClass().getClassLoader().getResourceAsStream(file + ".slog")
            case x => x
          }
          if(fStream == null) throw new NullPointerException() // crappy java
	  val reader = new jline.console.ConsoleReader(fStream, System.out)
	  reader.setHistoryEnabled(false)
	  reader.setExpandEvents(false) // for ! issue
	  reader
       } catch {
         case e: java.io.FileNotFoundException => val fn = new File(file)
           throw ParserException("The path I read is: " + fn.getCanonicalPath() + ", canRead=" + fn.canRead() + ", exists=" + fn.exists())
         case e: java.io.IOException => throw ParserException(s"Error reading file: $file")
         case e: NullPointerException => throw ParserException(s"Error reading file: $file")
         case _: Throwable => throw ParserException(s"Error reading file: $file")
       }
      case _ =>
	val reader = new jline.console.ConsoleReader(System.in, System.out)
        val historyFile: File = new File(System.getProperty("user.home") + "/.slang_history")
        if(historyFile.exists()) { // clear existing history if any
          historyFile.delete()
        }
	reader.setHistory(new FileHistory(historyFile))
	reader.setHistoryEnabled(true)
	reader.setExpandEvents(false) // for ! issue
        // reader.setBellEnabled(true)
        val completer = new StringsCompleter(replCmdSeq.asJavaCollection)
        reader.addCompleter(completer)
	reader
    }
  }

  // The main read-eval-print-loop aka REPL
  def repl(): Unit = {
    println(greet)
    readEval(consoleReader(None), stdPromptMsg, true)
    println("leaving")
  }

  def flushHistory(reader: jline.console.ConsoleReader): Unit =
    try {
      printLabel('info); println("Bye!") //Ctrl-D returns null
      reader.getHistory.asInstanceOf[jline.console.history.FileHistory].flush(); // TODO: check for auto-trimming or purging
    } catch {
      case e: Exception => {} // can raise when reading from a file since history is not set to false
    }

  protected def updatePromptSelf(): Unit = { }

  private def updateEnvContext(k: StrLit, v: EnvValue): Unit = {
    envContext.put(k, v)
    updatePromptSelf()
  }

  private def clearEnvContext(): Unit = {
    envContext.clear()
    updatePromptSelf()
  }


  protected def importProgram(pathname: String): SafeProgram = {
    compileAndLink(pathname)
  }

  private def evalReplCmd(cmd: Term): Boolean = {
    var executed = true

    cmd match {
      case Structure(StrLit("_is"), (v @ Variable(StrLit(vname), _, _, _)) +: rightterm +: Nil, _, _, _) =>
        //println(s"Set ${vname} to ${rightterm}.  rightterm.getClass=${rightterm.getClass}")
        //if(rightterm.isInstanceOf[Structure]) {
        //  println(s"rightterm.id=${rightterm.asInstanceOf[Structure].id}")
        //  println(s"rightterm.terms=${rightterm.asInstanceOf[Structure].terms}")
        //}
        //val rightval = solveAQuery(Query(Seq(cmd)))(envContext, Seq[Subcontext]()).map(f => f(v))
        try {
          val rightval = solveAQuery(Query(Seq(cmd)))(envContext, Seq(Subcontext("_tmp", _replStatements.toMap))).map(f => f(v))
          updateEnvContext(v.simpleName, rightval.head)
          printLabel('info)
          println(s"${v.simpleName.name}=${rightval.head}") //(${rightval})")
          //println(s"envContext=${envContext}")
        } catch {
          case ex: Throwable =>
             printLabel('failure)
             println(ex.toString)
        }

      case Structure(StrLit("clear"), Seq(Constant(StrLit("env"), _, _, _)), _, _, _) =>
        clearEnvContext()  // clear env variables

      case Constant(StrLit("clear"), _, _, _) | Structure(StrLit("clear"), Nil, _, _, _) =>
        printLabel('info); println("clear all")
        _assertionsInMemory.clear()
        _queriesInMemory.clear()
        _replStatements.clear()
        clearEnvContext()

      case Structure(StrLit("saveEnvTo"), Seq(Constant(StrLit(file), _, _, _)), _, _, _) =>
        try {
          val p = Repl.expandPathname(file)
          val pw = new PrintWriter(new File(p))
          envContext.foreach{ case (k, v) if v.isInstanceOf[Constant] => pw.write(s"""defenv ${k.name}() :- "${v.asInstanceOf[Constant].id.name}".\n""") }
          pw.close
        } catch {
          case ex: Throwable =>
             printLabel('failure)
             println(ex.toString)
        }

      case Structure(StrLit("runShellCmds"), Seq(Constant(StrLit(file), _, _, _)), _, _, _) =>
        val p = Repl.expandPathname(file)
        val source = scala.io.Source.fromFile(p)
        val _inputScanned = source.getLines.mkString("\n")
        _inputScanned.toString match {
          case str => parseCmdLine(str) match {
            case (Some(stmts), 'success) => // program includes all statement
              val program = addStatementsToRepl(stmts) // add to _replStatements
              // println(s"[Repl.evalReplCmd.runShellCmds] scanned stmts: $stmts")
              processShellCommands(stmts.toMap, true)
            case (None, 'continuation) =>
              println("Unexpected end of command list")
            case x@_ => // no messages other than parsing error messages
            // ignores quit.
          }
        }

      case Constant(StrLit("env"), _, _, _) | Structure(StrLit("env"), Nil, _, _, _) =>
 //       envContext.foreach{ case (k, v)  => println(s"${k.name}=$v")}
          for ((k,v) <- envContext) k match {
            case StrLit("Selfie") | StrLit("SelfKey") =>
              println(s"${k.name} -> ...")
            case _ => v match {
              case Constant(id, _, _, _) => println(s"${k.name}=${id.name}")
              case _ => println(s"${k.name} -> $v")
            }
          }

 //   This old code for env bails if it encounters a non-Constant v: no catch-all case.
 //   envContext.foreach{ case (k, v) if v.isInstanceOf[Constant] => println(s"${k.name}=${v.asInstanceOf[Constant].id.name}") }

      case Constant(StrLit("pwd"), _, _, _) | Structure(StrLit("pwd"), Nil, _, _, _) =>
        val workingDir: Path = Paths.get(".")
        println(workingDir.toFile.getCanonicalPath)

      case Constant(StrLit("ls"), _, _, _) | Structure(StrLit("ls"), Nil, _, _, _) =>
        //printLabel('info); println("list of assertions made so far ...")
        _assertionsInMemory.foreach(println)

      case Structure(StrLit("_fact"), Variable(StrLit("$Self"), _, _, _) +: Constant(StrLit("ls"), _, _, _) +: Nil, _, _, _)
         | Structure(StrLit("ls"), Nil, _, _, _) =>
        printLabel('info); println("list of assertions made so far ...")
        _assertionsInMemory.foreach(println)

      case Structure(StrLit("ls"), Seq(Constant(StrLit("all"), _, _, _)), _, _, _) =>
        //printLabel('info); println("list of all statements made so far...")
        _assertionsInMemory.foreach(println)
        _retractionsInMemory.foreach(println)
        _queriesInMemory.foreach(println)

      case Structure(StrLit("ls"), Seq(Constant(StrLit("facts"), _, _, _)), _, _, _) =>
        //printLabel('info); println("facts made so far ...")
        _assertionsInMemory.filter(_.terms.length < 2).foreach(println)

      case Structure(StrLit("ls"), Seq(Constant(StrLit("rules"), _, _, _)), _, _, _) =>
        printLabel('info); println("rules made so far ....")
        _assertionsInMemory.filter(_.terms.length > 1).foreach(println)

      case Structure(StrLit("ls"), Seq(Constant(StrLit("queries"), _, _, _)), _, _, _) =>
        printLabel('info); println("queries made so far ....")
        _queriesInMemory.foreach(println)

      case Structure(StrLit("ls"), Seq(Constant(StrLit("retractions"), _, _, _)), _, _, _) =>
        printLabel('info); println("retractions made so far ....")
        _retractionsInMemory.foreach(println)

      case Constant(StrLit("help"), _, _, _) | Structure(StrLit("help"), Nil, _, _, _) =>
        printLabel('info); println("commands list")
        println("help.                     display this message")
        println("env.                      list of envs")
        println("saveEnvTo(<file>)         save envs to a file")
        println("pwd.                      print working directory")
        println("import(<file>).           import file with name <file>")
        println("ls.                       list of assertions made so far")
        println("ls(facts).                list of facts made so far")
        println("ls(rules).                list of rules made so far")
        println("ls(queries).              list of queries made so far")
        println("ls(retractions).          list of retractions made so far")
        println("ls(all).                  list of all statements made so far")
        println("q().                      quit the interpreter")

      case Structure(StrLit("import"), xterms, _, _, _) =>
        val (filePathname, subjectSha) = xterms match {
           case Seq(Constant(filePathname, _, _, _)) => (filePathname, "")
           case Seq(Constant(filePathname, _, _, _), Constant(sub, _, _, _)) => (filePathname, sub)
        }
        printLabel('info); println(s"importing file ${filePathname.name} ...")
        //println(s"cmd.primaryIndex=${cmd.primaryIndex} \n  cmd.secondaryIndex=${cmd.secondaryIndex}")
        //_replStatements.remove(cmd.primaryIndex) // remove this import from cache to avoid unneeded recursion
        //_replStatements.remove(cmd.secondaryIndex)
        //_replStatements.keySet.foreach { k => println(s"index: ${k}  \n  statements: ${_replStatements(k)} \n ") }
        //scala.io.StdIn.readLine()

        var importedProgram = Map[Index, OrderedSet[Statement]]()
        try {
          val file = filePathname.name
          //val source = io.Source.fromFile(file).getLines.toList.mkString("\n")
          //val fStream = new java.io.InputStreamReader(new java.io.FileInputStream(file))
          //val fStream = new java.io.InputStreamReader(this.getClass().getClassLoader().getResourceAsStream(file))
          //val (knowledgeBase, time) = util.time(parse(fStream))

          //val (knowledgeBase, time) = util.time(parse(source))
          val (importedProgram, time) = util.time( importProgram( Repl.expandPathname(file) )  )
          addStatementsToRepl(importedProgram)  // Add statements to Repl cache
          logger.info(s"Time for import is $time seconds")
//          println("Imported in %f seconds".format(time))
        } catch {
          case ex: Exception =>
            println(s"Failed to parse ${filePathname.name}: ${ex}")
            return true
        }
        importedProgram.values().flatten.foreach {
          case s @ Assertion(stmt) => stmt.head match {
             case Structure(StrLit("import"), _, _, _, _) =>
               // evalReplCmd(stmt.head)
               println("[" + Console.RED + "Unexpected import" + Console.RESET + "] " + s)
             case _ => _assertionsInMemory += s
          }
          case s @ Retraction(stmt) => _retractionsInMemory += s
          case s @ Query(stmt) => _queriesInMemory += s
          case s @ QueryAll(stmt) => _queriesInMemory += s
          case x => println(s"Repl: Something is malformed during parsing, $x")
        }

      case Structure(StrLit("trace"), Seq(Constant(StrLit("on"), _, _, _)), _, _, _) => printLabel('info); println("starting the trace ...")
        //env._trace = true

      case Structure(StrLit("trace"), Seq(Constant(StrLit("off"), _, _, _)), _, _, _) => printLabel('info); println("trace is off ...")
        //env._trace = false

      case _ => executed = false
    }

    if(executed) { // already executed; remove the cmd
      _replStatements.remove(cmd.primaryIndex)
      true
    } else {
      false
    }
  }

  //val quit = """(q(uit)?\s*(\(\))?\s*[.?]+\s*$)""".r // q. | quit. | q(). | quit(). | q? | quit? | ..

  // Get a stream of input strings; Stream implements lazy lists where elements are evaluated only when they are needed
  @annotation.tailrec
  private def readEval(reader: jline.console.ConsoleReader, promptMsg: String = "", interactiveMode: Boolean = false): Seq[Statement] = {

    var end = false
    var uncompletedLine = false
    var scanit = true

    if (interactiveMode) reader.setPrompt(promptMsg)

    reader.readLine() match {
      case "" => scanit = false
      case null => _inputScanned.append("q.")
      case str => _inputScanned.append(str)
    }

    if (scanit) _inputScanned.toString match {
      case str => parseCmdLine(str) match {
        case (Some(stmts), 'success) =>
          val program = addStatementsToRepl(stmts) // add to _replStatements
          processShellCommands(stmts.toMap, interactiveMode)
        case (None, 'quit) =>
          end = true
          if (interactiveMode) flushHistory(reader)
        case (None, 'comment) => // a line starting with a comment
        case (None, 'paste) =>
          stdPromptMsg = " | "
          uncompletedLine = true
        case (None, 'continuation) => // empty line or incomplete statement
          stdPromptMsg = " | "
          uncompletedLine = true
        case (Some(stmt), 'builtIn) => // is it a builtIn? // TODO:
        // call the appropriate builtIn function
        // builtInHandler()
        //_assertionsInMemory -= stmt
        case (_, 'failure) =>
        case (_, 'error) =>
      }
    }
    if (!uncompletedLine) {
      _inputScanned.clear()
    }
    if (!end) {
      if (interactiveMode) readEval(reader, stdPromptMsg, true) else readEval(reader)
    } else {
      Nil
    }
  }



  // Chase 6/24/19: add processFact: called from processShellCommands, overridden for slang Repl.
  // The purpose is to process "facts" eagerly when using slang-shell, rather than storing them up.
  // Here we infer from code in processShellCmds that an "Assertion" has exactly one "Term" and that this "Term"
  // may be a "Structure" such as a :=.
  def processFact(cmd: Term): Boolean = {
//    logger.info("unabsorbed fact")
   false
  }



  def processShellCommands(commands: Map[Index, OrderedSet[Statement]], interactiveMode: Boolean = false): Unit = {

    def updateQuery(query: Statement, stmt: Seq[Term]): Unit = {
      if(interactiveMode && !evalReplCmd(stmt.head)) {
	_queriesInMemory += query
	_queriesInMemoryFresh += query
      }
      if(!interactiveMode) {
	_queriesInMemory += query
	_queriesInMemoryFresh += query
      }
    }

    try{
      commands.values().flatten.map {
         case assertion @ Assertion(stmt) =>
 /*
           Chase: 6/24/19.  Cleanup to always call evalReplCmd for assertions, even in non-interactive mode.
           Also: allow override for handling of unabsorbed "facts".
           This if statement replaces:
           if(interactiveMode && !evalReplCmd(stmt.head)) {
             _assertionsInMemory += assertion }
           if(!interactiveMode) _assertionsInMemory += assertion
  */
           if(!evalReplCmd(stmt.head) && (assertion.isFact() && !processFact(stmt.head)))
             _assertionsInMemory += assertion
           if(assertion.terms.head.id.name == "clear") throw new UnSafeException("clear")
         case query @ Query(stmt) =>
           _replStatements.remove(StrLit("_query"))
           updateQuery(query, stmt)
         case query @ QueryAll(stmt) =>
           _replStatements.remove(StrLit("_query"))
           updateQuery(query, stmt)
         case _ => Nil
       }
    } catch {
      case _: Throwable =>
    }
    // handle retractions
    commands.get(StrLit("_retraction")).map{r => r.foreach{rs => retractStatement(rs, _replStatements)}}

    if(_queriesInMemoryFresh.nonEmpty) {
      try {
        val programMap = _replStatements.toMap
        val (solutions: Seq[Seq[Statement]], time: Double) = util.time(solve(programMap, _queriesInMemoryFresh.toSeq, interactiveMode), 'ms)
        logger.info(s"Solve completed in $time milliseconds")
        //println(s"Solve completed in $time milliseconds")
        if(solutions.flatten.nonEmpty) true //printLabel('success) //println(s"""All solutions: ${solutions.mkString(", ")}""")
        else false // printLabel('failure)
      } catch {
        case ex: Throwable =>
          printLabel('failure)
          println(ex.toString)
          //logger.error(ex.toString)
      }
    }
    _queriesInMemoryFresh.clear()
    updatePromptSelf()
  }

  def retractStatement(
      statement: Statement
    , _program: MutableCache[Index, OrderedSet[Statement]]
  ): Unit = statement.terms match {

    case r @ Constant(StrLit("_withArity"), _, _, _) +: Constant(predicate, _, _, _) +: Constant(arity, _, _, _) +: Nil =>
      val index = StrLit(predicate.name + arity.name)
      val retraAssert: Seq[Statement] = _program.get(index) match {
        case None    => Nil
        case Some(x) => x.toSeq
      }
      _assertionsInMemory  --= retraAssert
      _retractionsInMemory  += Retraction(statement.terms)
      _program.remove(index)
      _program.remove(StrLit("_retraction"))
    case terms  =>
      val retraAssert = Assertion(terms)
      _assertionsInMemory  -= retraAssert
      _retractionsInMemory += Retraction(terms)
      val index = StrLit(statement.terms.head.id.name + statement.terms.head.arity)
      val stmts: OrderedSet[Statement] = _program.get(index).getOrElse(OrderedSet.empty)
      _program.put(index, stmts - retraAssert)
      _program.remove(StrLit("_retraction"))
  }

  def evalFileWithTime(fileName: String, unit: Symbol): Tuple2[Seq[Statement], Double] = util.time(evalOnFile(fileName).head, unit)
  def evalFileReaderWithTime(fileReader: java.io.BufferedReader, unit: Symbol): Tuple2[Seq[Statement], Double] = util.time(evalFileReader(fileReader).head, unit)

  def evalOnFile(fileName: String): Seq[Seq[Statement]] = {
    val fileReader = try {
      new java.io.BufferedReader(new java.io.FileReader(fileName))
    } catch {
      case e: java.io.FileNotFoundException => val fn = new java.io.File(fileName)
        throw ParserException("The path I read is: " + fn.getCanonicalPath() + ", canRead=" + fn.canRead() + ", exists=" + fn.exists())
      case e: java.io.IOException => throw ParserException(s"Error reading file: $fileName")
      case e: NullPointerException => throw ParserException(s"Error reading file: $fileName")
      case _: Throwable => throw ParserException(s"Error reading file: $fileName")
    }
    evalFileReader(fileReader)
  }

  def evalFileReader(fileReader: java.io.BufferedReader): Seq[Seq[Statement]] = {
    val res = util.time(parseAsSegments(fileReader), 'ms) match {
      case (statements, parseTime) => println("Parsing completed in %f milliseconds".format(parseTime))
        //val (res, solveTime) = util.time(solve(statements._1, statements._2, false), 'ms)
        // Change to solveInParallel
        val (res, solveTime) = util.time(solveInParallel(statements._1, statements._2, false), 'ms)
        println("Solve completed in %f milliseconds".format(solveTime))
        res
      case _ => Nil
    }
    res
  }

  def solveLocal(program: Map[Index, OrderedSet[Statement]], isInteractive: Boolean = false): Seq[Seq[Statement]] = {
    program.values.flatten.map {
      case assertion @ Assertion(stmt) =>
	_assertionsInMemory += assertion
      case retraction @ Retraction(stmt) =>
        val retraAssert = Assertion(retraction.terms)
        _assertionsInMemory -= retraAssert
	_retractionsInMemory += retraction
      case query @ Query(stmt) =>
	_queriesInMemory += query
	_queriesInMemoryFresh += query
      case query @ QueryAll(stmt) =>
	_queriesInMemory += query
	_queriesInMemoryFresh += query
      case _ => Nil
    }
    try {
      val (solutions: Seq[Seq[Statement]], time: Double) = util.time(solve(program, _queriesInMemoryFresh.toSeq, isInteractive), 'ms)
      logger.info(s"Solve completed in $time milliseconds")
      solutions
    } catch {
      case ex: Throwable =>
        logger.error(ex.toString)
        Nil
    }
  }

  def printOutput(out: Tuple2[Seq[Statement], Double]): Unit = out match {
    case (Nil, _) => printLabel('failure)
    case (_, 0.0) => printLabel('success)
      out._1.map(println(_))
      printLabel('info)
    case _ => printLabel('success)
      out._1.map(println(_))
      printLabel('info)
      logger.info("Run completed in %f milliseconds".format(out._2))
  }

  /*
  def importSets(statements: Seq[Statement]): SafeCache[SetId, CredentialSet] = {
    val importStatements = program.get('import1)
    if(importStatements == null) program
    else {
       importStatements foreach { stmt =>
         importProgram(stmt, program)
       }
    }
    program //TODO: yield and flatten?
  }

  def importProgram(stmt: Statement, program: ConcurrentHashMap[Index, Set[Statement]]): ConcurrentHashMap[Index, Set[Statement]] = stmt.terms.head match {
    case Structure('import, Seq(Constant(fileName))) => printLabel('info); println(s"importing program with name $fileName ...")
      val file = fileName.name
      val fStream = new java.io.InputStreamReader(this.getClass().getClassLoader().getResourceAsStream(file))
      val importedProgram = parse(fStream)
      dropStatement(stmt, program)
      importIfPresent(importedProgram)
    case _ => program
  }
  */
}

object Repl {

  import java.nio.file.{Path, Paths}

  //def apply() = new Repl(Config.config.self, Config.config.saysOperator)
  val inference = new Repl(Config.config.self, Config.config.saysOperator)

  def expandPathname(p: String, referencePath: Path = Paths.get(".")): String = {
    val tildeFree: String = p.replaceFirst("^~", System.getProperty("user.home"))
    //println(s"[safelog.Repl.expandPathname]  tildeFree: ${tildeFree}")
    val expanded: String = referencePath.resolve(tildeFree).toFile.getCanonicalPath
    //println(s"[safelog.Repl.expandPathname]  expanded: ${expanded}")
    expanded
  }

  def main(args: Array[String]): Unit = {

    val usage = """
      Usage: Repl [--file|-f fileName] [--help|-h]
    """

    val optionalArgs = Map(
        "--file"       -> 'file
      , "-f"           -> 'file
    )

    //println(s"[slog repl] Config.config.saysOperator: ${Config.config.saysOperator}")

    val argMap = Util.readCmdLine(args.toSeq, requiredArgs = Nil, optionalArgs, Map('help -> "false"))

    if(argMap('help) == "true") {
      println(usage)
    } else if(argMap.get('file).getOrElse("nil") != "nil") {
      inference.printOutput(inference.evalFileWithTime(argMap.get('file).get, 'ms)) // Evaluate expressions from a file.
    } else {
      inference.repl() // The init call
    }
    //throw new Exception("Incorrect arguments")
  }
}
