# IMPERIUM — Android ve PC strateji oyunu

IMPERIUM, çevrimdışı çalışacak şekilde geliştirilen tarihî strateji oyununun oynanabilir alfa sürümüdür. Web prototipi `index.html` üzerinden açılabilir; Android sürümü aynı oyun dosyasını yerel WebView içinde çalıştırır.

## Şu an oyunda bulunan sistemler
- MÖ 3000–MS 2026 arasında tarih seçimi, 19 medeniyet/devlet için kayıtlı hükümdarlar; ayrıca listede olmayan herhangi bir medeniyet ve hükümdar adını yazma, başlangıç bölgesini seçme.
- Dünya görünümünde 28 işaretli bölge, bölge seçimi ve temel devlet yönetimi.
- Hazine, gelir, asker toplama, tahkimat, sadakat ve isyan sistemi.
- Ordu yürüyüş süresi, meydan savaşı, kayıplar, geri çekilme ve kuşatma.
- Diplomatik hediye, ticaret, haraç, barış, ittifak ve savaş ilanı.
- Sarayda WebGL ile çizilen çevrimdışı 3D taht odası, divan salonu, elçi kabul odası ve iç avlu. WebGL desteklenmezse 2D yedek çizim kullanılır.
- Hükümdarlık süresi bitince veraset kararı ve hanedanı sürdürme seçeneği.
- Tarihî olay kayıtları ve cihazda yerel kayıt/yükleme.

## Android APK derleme
1. GitHub deposunda **Actions** sekmesini açın.
2. **Build IMPERIUM Android APK** iş akışını açın.
3. İşlem tamamlanınca **Artifacts** bölümünden `imperium-android-debug-apk` dosyasını indirin.
4. ZIP içindeki `app-debug.apk` dosyasını Android telefonda açın. Gerekirse Android ayarlarından bu kaynağa uygulama yükleme izni verin.

Her `index.html` veya `android/` değişikliğinde APK otomatik olarak yeniden derlenir.

## Dürüst kapsam notu
Bu sürüm oynanabilir bir alfa/prototiptir; tamamlanmış büyük strateji oyunu değildir. Harita 28 örnek bölgeyle temsil edilir, gerçek tarihî sınırlar ve tüm medeniyetlerin eksiksiz hükümdar/veri arşivi henüz yoktur. Saray sahnesi gerçekçi sinematik 3D varlıklar değil, WebGL ile oluşturulan düşük poligonlu 3D sahnedir. Savaş ve diplomasi sistemleri temel oyun kurallarıdır; henüz çok oyunculu veya gelişmiş yapay zekâ içermez. Bu sistemler sonraki geliştirme adımlarında genişletilecektir.
