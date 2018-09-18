package safe.safelang
package safesets

import safe.safelog.UnSafeException

import org.renci.io.swagger.client.{ApiClient, ApiException}
import org.renci.io.swagger.client.model.{Value, CometResponse};
import org.renci.io.swagger.client.api.DefaultApi;

import scala.util.{Success, Failure, Try}

import java.io.{File, FileInputStream, InputStream};
import java.security.KeyStore
import javax.net.ssl.KeyManagerFactory

/**
 * @DeveloperAPI
 * A client example running through typical Comet operations.
 */
object CometClientExample extends App {

  val apiClient = new ApiClient()
  apiClient.setBasePath("https://13.59.255.221:8111/")

  apiClient.setVerifyingSsl(false)
//  apiClient.applySslSettings

  val apiInstance = new DefaultApi(apiClient);
  val contextID: String = "04700364-ec9b-4958-b726-b063754a9143" 
  val family: String = "pubkeys" 
  val key: String = "key_example" 
  val readToken: String = "361a67ac" 
  val writeToken: String = "7b1c4d09"

  val enumerateScopeResult = Try(apiInstance.enumerateScopeGet(contextID, readToken, family))
  enumerateScopeResult match {
    case Success(r: CometResponse) =>
      println(r);
    case Failure(e) =>
      throw UnSafeException(s"enumerateScopeGet failed: ${contextID} ${readToken} ${family} ${e}")
  }

//
//    public static void main(String[] args) {
//        
//        DefaultApi apiInstance = new DefaultApi();
//        String contextID = "contextID_example"; // String | 
//        String family = "family_example"; // String | 
//        String key = "key_example"; // String | 
//        String readToken = "readToken_example"; // String | 
//        String writeToken = "writeToken_example"; // String | 
//        try {
//            CometResponse result = apiInstance.deleteScopeDelete(contextID, family, key, readToken, writeToken);
//            System.out.println(result);
//        } catch (ApiException e) {
//            System.err.println("Exception when calling DefaultApi#deleteScopeDelete");
//            e.printStackTrace();
//        }
//    }
//

}
