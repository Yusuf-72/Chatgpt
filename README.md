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


## Taktik muharebe komutası (alfa)

Ordu sekmesinde düşman bölgesine yürüyüş yaptıktan sonra meydan savaşı başlatılabilir. Oyuncu piyade, süvari, okçu ve yedek kuvvetlere ayrı emir verir; mevzi koruma, ilerleme, hücum, kanat saldırısı, salvo ve yedekte tutma seçeneklerini kullanır. Dengeli hat, geniş hat, derin kol, kama ve savunma düzenleri ile kontrollü/agresif/temkinli tempo seçilebilir. Her komut turunda düşman karşı saldırı yapar; kayıplar, moral, zafer, yenilgi ve düzenli geri çekilme hesaplanır.

Bu sistem oynanabilir bir taktik savaş prototipidir. Gerçek zamanlı 3B savaş alanı, animasyonlu asker modelleri ve tarihsel olarak doğrulanmış kapsamlı birlik/komutan veri tabanı henüz mevcut değildir.


## Ordu ikmali ve komutan gelişimi

- Sefer ordusu erzak stoğu taşır; her yıl asker sayısına bağlı ikmal tüketimi olur.
- İkmal tükenirse firar/açlık kayıpları, moral ve istikrar kaybı oluşur.
- Yürüyüş mesafesi erzak tüketir ve yorgunluğu artırır.
- Erzak satın alma, araziden iaşe toplama ve dinlenme seçenekleri vardır.
- Başkomutan seçimi muharebe performansını etkiler; zaferler komutan tecrübesi kazandırır.

Bu lojistik katmanı strateji prototipidir; gerçek zamanlı yol bulma, ikmal konvoyları ve tarihsel komutan biyografileri henüz kapsamlı değildir.


## Güncel geliştirme notu

Harita prototipi 28 örnek bölgeye genişletildi. Diplomasi ekranında savaş ilanı, ittifak ve barışla savaşı bitirme akışları bulunur. Savaş ve kuşatma başlatmak için hedef devletle savaş hâlinde olmak gerekir. Bu harita hâlâ bölgesel bir oyun haritasıdır; tüm dünya sınırlarını ve her tarih için gerçek egemenlikleri içermez.


## Oyunda savaş komutasını deneme

1. Diplomasi sekmesinde Bizans'ı seç ve **Savaş ilan et** düğmesine bas.
2. Ordu & Kuşatma sekmesinde hedef olarak Edirne'yi seçip yürüyüş emri ver.
3. Aynı sekmedeki **Meydan savaşı başlat** düğmesini kullan.
4. Birlik, taktik emir, ordu düzeni ve savaş temposunu seçerek her turda **Emri uygula ve turu işlet** düğmesine bas.
5. Erzak ve yorgunluğu takip et; gerektiğinde ikmal satın al, iaşe topla veya dinlen.
6. Durum kötüleşirse düzenli geri çekil. Zaferde bölge ele geçirilir ve komutan tecrübe kazanır.

APK derlemesi için GitHub deposunda Actions sekmesini aç. En son **Build IMPERIUM Android APK** çalışmasının tamamlanmasını bekle; başarılı çalışmanın özetindeki `imperium-android-debug-apk` artifact'ini indirip ZIP içinden `app-debug.apk` dosyasını çıkar.


## Yeni savaş ve kuşatma geliştirmeleri
- Meydan muharebelerinde bölgeye göre arazi etkileri bulunur: ova ve bozkır süvariyi, dağlık arazi piyadeyi, yüksek plato okçuları destekler.
- Kuşatmada altın karşılığında kuşatma makineleri kurulabilir; bunlar kuşatma baskısını ve hücum etkinliğini artırır.
- Tam abluka savunmacının ikmalini keserek teslimiyeti hızlandırır; kuşatma ordusu da her yıl ikmal tüketir.
- Savunmacı teslim olduğunda veya kuşatma ilerlemesi tamamlandığında bölge otomatik olarak teslim alınır.
- Bu sistemler oyunlaştırılmış alfa simülasyonlarıdır; tarihsel savaş simülasyonu veya gerçek zamanlı taktik motoru değildir.
