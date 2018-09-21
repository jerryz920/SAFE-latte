package safe.server

import java.util.concurrent.TimeUnit

import scala.util.Try

import akka.util.Timeout

import com.typesafe.config.{ConfigException, ConfigFactory}

class Config(config: com.typesafe.config.Config) {

  config.checkValid(ConfigFactory.defaultReference(), "safeServer")

  def this() {
    this(ConfigFactory.load())
  }

  val restIP: String             = Try(config.getString("safe.service.interface")).getOrElse("0.0.0.0")
  val restPort: Int              = Try(config.getInt("safe.server.port")).getOrElse(7777)
  val storeURI: String           = Try(config.getString("safe.safesets.storeURI")).getOrElse("")
  val requestTimeout: Timeout    = Timeout(config.getDuration("safe.service.requestTimeout", TimeUnit.SECONDS), TimeUnit.SECONDS)
  val keyPairDir: String         = Try(config.getString("safe.multiprincipal.keyPairDir")).getOrElse("")
}

object Config {
  val config = new Config(ConfigFactory.load("application")) // default config context
}
