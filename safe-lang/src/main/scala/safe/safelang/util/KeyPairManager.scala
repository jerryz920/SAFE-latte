package safe.safelang
package util

import java.io.File
import java.io.PrintWriter
import java.security.spec._
import javax.crypto._
import javax.crypto.spec._

import scala.collection.mutable.{Map => MutableMap}

import org.apache.commons.io.FilenameUtils
import com.typesafe.scalalogging.LazyLogging

import model.Principal
import safe.safelog.{SetId, StrLit}
import safe.safelang.model.Identity

/*
 * KeyPairManager is stateless but modifies maps passed as its arguments.  Yikes!
 * Inference* and SafelangManager extend it: SafelangManager keeps its maps internally,
 * but Inference* doesn't really manage keypairs at all.  Better to use composition here: KeyPairManager
 * should be stateful, encapsulated, and always present at the lowest level.
 */

trait KeyPairManager extends LazyLogging {

  // Chase 6/28/19: adding state for internal use
  // Really these should be immutable after first load, with a mutable on the side for later additions.
  // Otherwise the locking in here is inadequate.
  private val nameToPid = MutableMap[String, String]()
  private val pidToPrincipal = MutableMap[String, Principal]()

  /** 
   * Helpers for operating on directories of key files.
   */
  def filepathsOfDir(dirStr: String): Seq[String] = {
    val dir = new File(dirStr)
    if (!dir.exists) {
      logger.error(s"KeyPair directory: path $dirStr does not exist")
      Seq[String]()
    } else if (!dir.isDirectory) {
      logger.error(s"KeyPair directory: path $dirStr is not a directory")
      Seq[String]()
    } else {
      dir.listFiles.filter(_.isFile).toSeq.map(_.toString).filter(FilenameUtils.getExtension(_) == "key")
    }
  }

  def filenamesOfDir(dirStr: String): Seq[String] = {
    val dir = new File(dirStr)
    if(dir.exists && dir.isDirectory) {
      dir.listFiles.filter(_.isFile).toSeq.map(_.getName)
    } else {
      Seq[String]()
    }
  }

  def filesOfDir(dirStr: String): Seq[File] = {
    val dir = new File(dirStr)
    if(dir.exists && dir.isDirectory) {
      dir.listFiles.filter(_.isFile).toSeq
    } else {
      Seq[File]()
    }
  }

  /**
   * We may store principal ids (token of the public keys) to
   * a file after loading them.
   *
   * Get the absolute path to the file of principal pids 
   */
  def pathToPidsFile(dirStr: String, filename: String): String = {
    dirStr + "keyhashes/" + filename
  }

  def loadKeyPairs(): MutableMap[String, Principal] = {
    loadKeyPairs(Config.config.keyPairDir)
  }

  def loadKeyPairs(filepaths: Seq[String], nameToID: MutableMap[String, String], serverPrincipalSet: MutableMap[String, Principal]): Unit = {
    println(s"[KeyPairManager] Number of keys: ${filepaths.size}")
    logger.info(s"Loaded principals:")    
    var count = 0
    for(fname <- filepaths) {
      //println(s"[KeyPairManager loadKeyPairs] fname=${fname}");
      val p = Principal(pemFile = fname)
      val pid = p.pid
      serverPrincipalSet.synchronized {
        serverPrincipalSet.put(pid, p)
      }
      val pname = fname.substring(fname.lastIndexOf('/')+1, fname.lastIndexOf('.'))
      nameToID.synchronized {
        nameToID.put(pname, pid)
      }
      logger.info(s"${pname}: ${pid}")
      //println(s"[KeyPairManager loadKeyPairs] fname=${fname};    p.subject.id.toString=${p.subject.id.toString};    p.scid.toString=${p.scid.toString};   p.scid.speakerId.toString=${p.scid.speakerId.toString};     p.scid.name=${p.scid.name};     p=${p}")
      count += 1
      if(count % 10000 == 0)
        println(s"[KeyPairManager]  count = ${count}")
    }
  }


  def loadKeyPairs(dir: String, nameToID: MutableMap[String, String] = MutableMap[String, String]()): MutableMap[String, Principal] = {
    val serverPrincipalSet = MutableMap[String, Principal]()   
    if(dir.isEmpty) return serverPrincipalSet
    val filepaths = filepathsOfDir(dir)
    println(s"[KeyPairManager] Loading keys from ${dir}")
    loadKeyPairs(filepaths, nameToID, serverPrincipalSet)
    serverPrincipalSet
  }

  /*
   * Chase 6/28/19.  New alternate API, to be incrementally deployed and ultimately replace all the old loadKeyPairs uses.
   * Also to support better/cleaner indexing for principal switches, e.g., in Repl.
   */

  def loadPrincipals(dir:String): Unit = {
    logger.info(s"[KeyPairManager] Loading principal keys from ${dir}")
    val filepaths = filepathsOfDir(dir)
    loadKeyPairs(filepaths, nameToPid, pidToPrincipal)
    /* If something goes wrong we get a logged error but empty maps. */
  }

  def getPrincipal(pspec: String): Option[Principal] = {
    val optP  = pidToPrincipal.get(pspec)
    if (optP.isDefined)
      optP
    else {
      val optPid = nameToPid.get(pspec)
      optPid match {
        case None =>
          logger.info(s"[KeyPairManager] getPrincipal: no match for $pspec")
        case Some(pid: String) =>
          logger.info(s"[KeyPairManager] getPrincipal: found pid for $pspec")
      }
      optPid.map(pidToPrincipal)
    }
  }
 
  /**
   * TODO: move part of utilities in safe.safelang.model._ to here, 
   * such as:
   * Principal.keyPairFromFile(pemFile: String)
   * Identity.hash()
   */

  /* Load access keys from a local directory */
  def loadAccessKeys(dir: String): MutableMap[String, SecretKeySpec] = {
    val accessKeySet = MutableMap[String, SecretKeySpec]()
    val kdir = new File(dir) 
    if(kdir.exists && kdir.isDirectory) {
      val kfiles = kdir.listFiles.filter(_.isFile).toSeq
      for(kf <- kfiles) {
        val path = kf.toString
        val name = kf.getName
        val keySpec = loadAccessKey(path)
        accessKeySet.put(name, keySpec) 
      }
    }
    accessKeySet
  }

  def loadAccessKey(path: String): SecretKeySpec = {
    val base64EncodedString: String = scala.io.Source.fromFile(path).mkString
    val aesKey: Array[Byte] = Identity.base64Decode(base64EncodedString)
    val aesKeySpec = new SecretKeySpec(aesKey, "AES")
    aesKeySpec
  }

  def createAESKey(keyLen: Int): SecretKey = {
    val kgen: KeyGenerator = KeyGenerator.getInstance("AES")
    kgen.init(keyLen)
    val key: SecretKey = kgen.generateKey()
    key
  }

  def saveAESKey(key: SecretKey, path: String): String = {
    val aesKey: Array[Byte] = key.getEncoded()
    val keyAsString: String = Identity.base64EncodeURLSafe(aesKey)
    val pw = new PrintWriter(new File(path))
    pw.write(keyAsString)
    pw.close()
    keyAsString
  }

  /* AES encryption */
  def encrypt(data: Array[Byte], accessKeySpec: SecretKeySpec): Array[Byte] = {
    val aesCipher = Cipher.getInstance("AES")
    aesCipher.init(Cipher.ENCRYPT_MODE, accessKeySpec)
    val cipherdata = aesCipher.doFinal(data) 
    cipherdata
  }

  /* AES decryption */
  def decrypt(cipherdata: Array[Byte], accessKeySpec: SecretKeySpec): Array[Byte] = {
    val aesCipher = Cipher.getInstance("AES")
    aesCipher.init(Cipher.DECRYPT_MODE, accessKeySpec)
    val plaindata = aesCipher.doFinal(cipherdata) 
    plaindata
  }
 
}
