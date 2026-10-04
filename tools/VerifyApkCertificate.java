import com.android.apksig.ApkVerifier;
import com.android.apksig.SigningCertificateLineage;
import java.io.File;
import java.security.MessageDigest;
import java.security.cert.X509Certificate;
import java.util.HexFormat;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

/** Verifies the APK with the selected Android Build Tools library, without a keystore. */
public class VerifyApkCertificate {
    private static final String PREFIX = "KT_APK_CERT_V1 ";

    private static void reject(String status) {
        System.out.println(PREFIX + status);
        System.exit(1);
    }

    private static void add(Set<String> observed, X509Certificate certificate) throws Exception {
        if (certificate == null) {
            reject("SIGNERS");
        }
        observed.add(HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256").digest(certificate.getEncoded())));
    }

    private static void checkLineage(Set<String> observed, SigningCertificateLineage lineage)
            throws Exception {
        if (lineage == null) {
            return;
        }
        List<X509Certificate> certificates = lineage.getCertificatesInLineage();
        if (certificates.size() != 1) {
            reject("ROTATION");
        }
        add(observed, certificates.get(0));
    }

    public static void main(String[] args) {
        try {
            if (args.length != 2 || !args[1].matches("[0-9a-f]{64}")) {
                reject("TOOL");
            }
            // Keep the manifest's minimum SDK and the library's complete supported range.
            ApkVerifier.Result result = new ApkVerifier.Builder(new File(args[0])).build().verify();
            if (!result.isVerified()) {
                reject("CRYPTO");
            }
            if (result.getSignerCertificates().size() != 1
                    || result.getV1SchemeSigners().size() > 1
                    || result.getV2SchemeSigners().size() > 1) {
                reject("SIGNERS");
            }
            Set<String> observed = new TreeSet<>();
            add(observed, result.getSignerCertificates().get(0));
            // Only leaf signing certificates: neither certificate chains nor Source Stamp.
            for (var signer : result.getV1SchemeSigners()) {
                add(observed, signer.getCertificate());
            }
            for (var signer : result.getV2SchemeSigners()) {
                add(observed, signer.getCertificate());
            }
            // v3/v3.1 may contain SDK-specific signers. Every one must keep this identity.
            for (var signer : result.getV3SchemeSigners()) {
                add(observed, signer.getCertificate());
                checkLineage(observed, signer.getSigningCertificateLineage());
            }
            for (var signer : result.getV31SchemeSigners()) {
                add(observed, signer.getCertificate());
                checkLineage(observed, signer.getSigningCertificateLineage());
            }
            checkLineage(observed, result.getSigningCertificateLineage());
            if (!observed.equals(Set.of(args[1]))) {
                reject("MISMATCH " + String.join(",", observed));
            }
            System.out.println(PREFIX + "OK " + args[1]);
        } catch (Exception | LinkageError error) {
            // No exception message, certificate subject or third-party output is forwarded.
            reject("TOOL");
        }
    }
}
