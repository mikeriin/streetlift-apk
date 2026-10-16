import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.jar.JarFile;

/** Verifies every payload entry using JAR signatures; an AAB is not an APK. */
public class VerifyBundleSignature {
    public static void main(String[] args) {
        try {
            if (args.length != 2 || !args[1].matches("[0-9a-f]{64}")) throw new IllegalArgumentException();
            var names = new HashSet<String>();
            int payloads = 0;
            boolean manifest = false;
            try (var jar = new JarFile(Path.of(args[0]).toFile(), true)) {
                var entries = jar.entries();
                byte[] buffer = new byte[32768];
                while (entries.hasMoreElements()) {
                    var entry = entries.nextElement();
                    if (!names.add(entry.getName())) throw new SecurityException();
                    if (entry.isDirectory()) continue;
                    // Reading to EOF triggers the JDK's cryptographic verification.
                    try (var stream = jar.getInputStream(entry)) {
                        while (stream.read(buffer) != -1) { }
                    }
                    if (entry.getName().matches("(?i)META-INF/(MANIFEST\\.MF|[^/]+\\.(SF|RSA|DSA|EC))")) continue;
                    var signers = entry.getCodeSigners();
                    if (signers == null || signers.length != 1) throw new SecurityException();
                    var leaf = signers[0].getSignerCertPath().getCertificates().get(0);
                    String digest = HexFormat.of().formatHex(
                        MessageDigest.getInstance("SHA-256").digest(leaf.getEncoded()));
                    if (!digest.equals(args[1])) throw new SecurityException();
                    payloads++;
                    manifest |= entry.getName().equals("base/manifest/AndroidManifest.xml");
                }
            }
            if (!manifest || payloads == 0) throw new SecurityException();
            System.out.println("KT_AAB_CERT_V1 OK " + args[1]);
        } catch (Exception | LinkageError error) {
            System.err.println("Signature AAB absente, invalide, partielle ou différente de la référence.");
            System.exit(1);
        }
    }
}
