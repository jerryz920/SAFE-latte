package safe.benchmark

import safe.safelang.model._
import util._
import safe.safelang._
import safe.safelog._

import java.security.{PublicKey, KeyPair}

/**
 * Local stub of a remote principal
 */
class PrincipalStub (
    protected val pid: String,                     // Principal id: hash of public key
    protected val canonicalName: String,           // Symbolic name of the principal
    protected val serverJvm: String,               // Address of the principal's JVM
    protected var credSetTokens: Seq[String],      // Tokens of credential sets, including subject set 
    protected val keyFile: String                  // Key file pathname
  ) extends Serializable with SlangObjectHelper {

  def this(publicKey: PublicKey, cn: String, serverJvm: String, subjectSetTokens: String) {
    this(PrincipalStub.pidFromPublicKey(publicKey), cn, serverJvm, Seq(subjectSetTokens), "")
  }

  def this(publicKey: PublicKey, cn: String, serverJvm: String, credTokens: Seq[String]) {
    this(PrincipalStub.pidFromPublicKey(publicKey), cn, serverJvm, credTokens, "")
  }

  def this(publicKey: PublicKey, cn: String, serverJvm: String) {
    this(publicKey, cn, serverJvm, Seq[String]())
  }
 
  def this(publicKey: PublicKey, serverJvm: String, credTokens: Seq[String]) {
    this(PrincipalStub.pidFromPublicKey(publicKey), "", serverJvm, credTokens, "")
  }

  def this(publicKey: PublicKey, serverJvm: String) {
    this(publicKey, "", serverJvm, Seq[String]())
  }
 
  def this(keyFile: String, cn: String, serverJvm: String, credTokens: Seq[String]) {
    this(PrincipalStub.pidFromFile(keyFile), cn, serverJvm, credTokens, keyFile)
  }
 
  def this(keyFile: String, cn: String, serverJvm: String) {
    this(keyFile, cn, serverJvm, Seq[String]())
  }

  def this(keyFile: String, serverJvm: String, credTokens: Seq[String]) {
    this(PrincipalStub.pidFromFile(keyFile), "", serverJvm, credTokens, keyFile)
  }
 
  def this(keyFile: String, serverJvm: String) {
    this(keyFile, "", serverJvm, Seq[String]())
  }

  /* DeveloperAPI */
  override def toString(): String = {
    s"""|Principal info: 
        |${pid}
        |${canonicalName}
        |${serverJvm}
        |${subjectSetTokens}
        |${keyFile}""".stripMargin
  }

  def getPid(): String = pid
  def getCN(): String = canonicalName
  def getJvm(): String = serverJvm
  def getCredSetTokens: Seq[String] = credSetTokens
  def getKeyFile(): String = keyFile


  /** 
   * APIs to call local slang instance
   */

  def queryLocalSlang(inference: Safelang, goal: String, args: Seq[Constant]): Seq[Seq[Statement]] = {
    val query = Query(Seq(Structure(goal, args)))
    val res: Seq[Seq[Statement]] = inference.solveSlang(Seq(query), false)
    res
  } 

  def queryAndExtractToken(inference: Safelang, goal: String, args: Seq[Constant]): String = {
    val res: Seq[Seq[Statement]] = queryLocalSlang(inference, goal, args)
    val token = firstTokenOfInferredResult(res)
    token
  } 


  /** APIs for remote slang call (defcall) */

  /**
   * @return settoken 
   *  
   * Make a simple remote call to host server. The remote call is simple as the call follows 
   * a simple convention (see below) and expects a token returned from the server.
   * entryPoint(?ServerJVM, ?ServerPrincipal, ?Envs, ?Args) 
   */
  def simpleRemoteCall(inference: Safelang, entryPoint: String, 
      envs: String = emptyEnvs, args: Seq[String] = Seq()): String = {
    val queryArgs = (Seq(serverJvm, pid, envs) ++ args).map(s => buildConstant(s))
    val token: String = queryAndExtractToken(inference, entryPoint, queryArgs)
    token
  }

  /**
   * Remote call to a target server, rather than the host server 
   * The caller must ensure that the principal is installed on the server
   */
  def remoteCallToServer(inference: Safelang, entryPoint: String, specifiedJvm: String, 
      envs: String = emptyEnvs, args: Seq[String] = Seq()): String = {
    val queryArgs = (Seq(specifiedJvm, pid, envs) ++ args).map(s => buildConstant(s))
    val token: String = queryAndExtractToken(inference, entryPoint, queryArgs)
    token
  }


  /** Common operations for SAFE principals */

  /**
   * Format of postRawIdSet defcall in local Slang:
   * defcall postRawIdSet(?JVM, ?Principal, ?Envs, ?CN)
   */
  def postIdSet(inference: Safelang): String = {
    simpleRemoteCall(inference, "postRawIdSet", args=Seq(canonicalName)) 
  }

  /**
   * Format of postSubjectSet defcall in local Slang: 
   * defcall postSubjectSet(?JVM, ?Principal, ?Envs)
   */
  def postSubjectSet(inference: Safelang): String = {
    simpleRemoteCall(inference, "postSubjectSet")
  }

  /**  
   * Post subject set and store the token into credSetTokens
   * A principal could have multiple cred sets. Tokens are
   * stored in order when cred sets are created.
   */ 
  def postSubjectSetAndPlaceToken(inference: Safelang): Unit = {
    val token = postSubjectSet(inference)
    if(!credSetTokens.contains(token)) { 
      // Add the token into the subject token set if it hasn't been added yet
      credSetTokens = credSetTokens :+ token
    }
  }

  /**
   * Update subject set with a token
   */
  def updateSubjectSet(inference: Safelang, token: String): String = {
    simpleRemoteCall(inference, "updateSubjectSet", args=Seq(token))
  } 
}

object PrincipalStub {
  def pidFromFile(pemFile: String): String = {
    val publicKey = publicKeyFromFile(pemFile)
    pidFromPublicKey(publicKey)
  }

  def publicKeyFromFile(pemFile: String): PublicKey = {
    val keyPair: KeyPair = Principal.keyPairFromFile(pemFile)
    keyPair.getPublic()
  }

  def pidFromPublicKey(publicKey: PublicKey): String = {
    Identity.encode(Identity.hash(publicKey.getEncoded()))
  } 
}
