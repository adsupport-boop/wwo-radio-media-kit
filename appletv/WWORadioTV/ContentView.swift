import SwiftUI

struct ContentView: View {
    @EnvironmentObject var radio: RadioPlayer
    private let accent = Color(red: 0.35, green: 0.80, blue: 0.95)
    private let silver = Color(red: 0.80, green: 0.84, blue: 0.90)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.02, green: 0.04, blue: 0.10),
                                    Color(red: 0.05, green: 0.12, blue: 0.30)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            HStack(spacing: 100) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 560, height: 560)
                    .shadow(color: accent.opacity(0.45), radius: 40)

                VStack(alignment: .leading, spacing: 28) {
                    HStack(spacing: 14) {
                        Circle().fill(radio.isPlaying ? Color.red : Color.gray).frame(width: 18, height: 18)
                        Text(radio.isPlaying ? "LIVE" : "WWO RADIO 96.9")
                            .font(.system(size: 30, weight: .bold)).tracking(4).foregroundColor(silver)
                    }
                    Text("NOW PLAYING")
                        .font(.system(size: 28, weight: .semibold)).tracking(6).foregroundColor(accent)
                    Text(radio.title)
                        .font(.system(size: 68, weight: .heavy)).foregroundColor(.white)
                        .lineLimit(2).minimumScaleFactor(0.6)
                    Text(radio.artist)
                        .font(.system(size: 40, weight: .medium)).foregroundColor(silver)
                        .lineLimit(1)
                    Text("R&B · Hip-Hop · Slow Jams · House · Steppers · Talk")
                        .font(.system(size: 26)).foregroundColor(silver.opacity(0.7))

                    Button(action: { radio.toggle() }) {
                        HStack(spacing: 18) {
                            Image(systemName: radio.isPlaying ? "pause.fill" : "play.fill")
                            Text(radio.isPlaying ? "Pause" : "Listen Live")
                        }
                        .font(.system(size: 38, weight: .bold))
                        .padding(.horizontal, 40).padding(.vertical, 14)
                    }
                    .padding(.top, 20)

                    Text(radio.status)
                        .font(.system(size: 26)).foregroundColor(silver.opacity(0.75))
                }
                .frame(maxWidth: 900, alignment: .leading)
            }
            .padding(80)
        }
    }
}
