import SwiftUI
import UserNotifications

// Dalga Animasyonu Şekli
struct Wave: Shape {
    var offset: Angle
    var percent: Double
    
    var animatableData: Double {
        get { offset.degrees }
        set { offset = Angle(degrees: newValue) }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let lowfudge = 0.02
        let highfudge = 0.98
        let newpercent = lowfudge + (highfudge - lowfudge) * percent
        let waveHeight = 0.025 * rect.height
        let yoffset = CGFloat(1 - newpercent) * (rect.height - 4 * waveHeight) + 2 * waveHeight
        let startAngle = offset
        let endAngle = offset + Angle(degrees: 360)
        
        path.move(to: CGPoint(x: 0, y: yoffset + waveHeight * CGFloat(sin(offset.radians))))
        
        for angle in stride(from: startAngle.degrees, through: endAngle.degrees, by: 5) {
            let x = CGFloat((angle - startAngle.degrees) / 360) * rect.width
            path.addLine(to: CGPoint(x: x, y: yoffset + waveHeight * CGFloat(sin(Angle(degrees: angle).radians))))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct ContentView: View {
    // Verileri telefonda kalıcı saklar
    @AppStorage("icilenSu") private var icilenSu: Int = 0
    @AppStorage("sonKayitGunu") private var sonKayitGunu: String = ""
    @AppStorage("hatirlaticiAktif") private var hatirlaticiAktif: Bool = false
    
    @State private var waveOffset = Angle(degrees: 0)
    @State private var motivasyonMesaji: String = "Bugün kendine iyi bakmayı unutma 💙"
    
    let gunlukHedef: Int = 2000 // Günlük 2000 ml (2 Litre) hedef
    
    // Ekranda değişecek tatlı mesajlar (Burayı istediğin gibi özelleştir)
    let mesajlar = [
        "Harikasın! Cildin ve enerjin sana teşekkür ediyor ✨",
        "Bir bardak daha! Hedefe adım adım yaklaşıyorsun 💧",
        "Su içen güzelliğine güzellik katar ❤️",
        "Böyle devam et sevgilim, harika gidiyorsun! 🌟",
        "Su hayattır, sen benim hayatımsın 💙"
    ]
    
    var dolulukOrani: Double {
        min(Double(icilenSu) / Double(gunlukHedef), 1.0)
    }
    
    var body: some View {
        ZStack {
            // Arka plan yumuşak geçişi
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.12), Color.cyan.opacity(0.05), Color.white]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Üst Başlık
                VStack(spacing: 6) {
                    Text("Günlük Su Takibin")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(motivasyonMesaji)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .animation(.easeInOut, value: motivasyonMesaji)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Dairesel Dalgalı Su Tankı
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.blue.opacity(0.15), radius: 20, x: 0, y: 10)
                    
                    // Dalga Katmanı 1 (Arka)
                    Wave(offset: waveOffset + Angle(degrees: 180), percent: dolulukOrani)
                        .fill(Color.cyan.opacity(0.4))
                        .clipShape(Circle())
                    
                    // Dalga Katmanı 2 (Ön)
                    Wave(offset: waveOffset, percent: dolulukOrani)
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                           startPoint: .top,
                                           endPoint: .bottom)
                        )
                        .clipShape(Circle())
                    
                    // Orta Yazı Göstergesi
                    VStack(spacing: 4) {
                        Text("\(icilenSu) ml")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundColor(dolulukOrani > 0.55 ? .white : .blue)
                        
                        Text("Hedef: \(gunlukHedef) ml")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(dolulukOrani > 0.45 ? .white.opacity(0.9) : .secondary)
                        
                        if icilenSu >= gunlukHedef {
                            Text("🎉 Günlük Hedef Tamamlandı!")
                                .font(.caption)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.25))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .padding(.top, 4)
                        }
                    }
                }
                .frame(width: 260, height: 260)
                
                Spacer()
                
                // Bardak Seçenekleri Butonları
                VStack(spacing: 12) {
                    Text("Ne kadar su içtin?")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 15) {
                        suEkleButonu(miktar: 200, etiket: "Bardak", ikon: "cup.and.saucer.fill")
                        suEkleButonu(miktar: 330, etiket: "Kupa", ikon: "mug.fill")
                        suEkleButonu(miktar: 500, etiket: "Şişe", ikon: "waterbottle.fill")
                    }
                }
                .padding(.horizontal)
                
                // Alt Kontrol Barı (Hatırlatıcı & Sıfırlama)
                HStack(spacing: 20) {
                    Button(action: {
                        hatirlaticilariAyarla()
                    }) {
                        HStack {
                            Image(systemName: hatirlaticiAktif ? "bell.badge.fill" : "bell.fill")
                            Text(hatirlaticiAktif ? "Hatırlatıcı Açık" : "Hatırlatıcıyı Kur")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(hatirlaticiAktif ? Color.green : Color.blue)
                        .cornerRadius(14)
                    }
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            icilenSu = max(0, icilenSu - 200)
                        }
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.subheadline.bold())
                            .foregroundColor(.blue)
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(14)
                    }
                }
                .padding(.bottom, 25)
            }
        }
        .onAppear {
            gunKontroluYap()
            withAnimation(Animation.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                self.waveOffset = Angle(degrees: 360)
            }
        }
    }
    
    // Özel Buton Tasarımı
    func suEkleButonu(miktar: Int, etiket: String, ikon: String) -> some View {
        Button(action: {
            // Titreşim efekti
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                icilenSu += miktar
                motivasyonMesaji = mesajlar.randomElement() ?? motivasyonMesaji
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: ikon)
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("+\(miktar) ml")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(etiket)
                    .font(.caption2)