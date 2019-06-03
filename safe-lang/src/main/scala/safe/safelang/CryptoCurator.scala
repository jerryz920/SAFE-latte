package safe.safelang

import java.security.{ MessageDigest, Provider, Security }
import java.security.Provider.Service
import scala.collection.JavaConverters._
// import java.util.{ ArrayList, List, Set }

class CryptoCurator {

  def showHashAlgorithms(p: Provider, t: Class[_]): Unit = {
    val typ = t.getSimpleName
    println(s"Provider: ${p.getName}    Looking into class ${typ}   t.getClass ${t.getClass}")

    var algos = List[Service]()

    val services = p.getServices.asScala
    // println(s"services.getClass: ${services.getClass}")
    services.foreach{ service =>
      if (service.getType().equalsIgnoreCase(typ))
        algos = algos :+ service
    }

    if (!algos.isEmpty) {
      println(s" --- Provider ${p.getName}, version ${p.getVersion} ---")
      algos.foreach { service =>
        val algo: String = service.getAlgorithm
        println(s"""Algorithm name: \"${algo}\"""")
      }
    }

    // --- find aliases (inefficiently)
    val keys = p.keySet.asScala
    // println(s"Alias keys.getClass: ${keys.getClass}")
    keys.foreach { key =>
      val prefix: String = "Alg.Alias." + typ + "."
      if (key.toString.startsWith(prefix)) {
        val value: String = p.get(key.toString).toString
        println(s"""Alias: \"${key.toString.substring(prefix.length())}\" -> \"${value}\"""")
      }
    }
  }
}

object CryptoCurator extends App {
  val c = new CryptoCurator()
  val providers = Security.getProviders()
  println(s"Number of providers: ${providers.size}")
  providers.foreach { p =>
    println(s"provider class: ${p.getClass}")
    c.showHashAlgorithms(p, classOf[MessageDigest]) }
}
