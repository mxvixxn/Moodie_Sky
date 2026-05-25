import SwiftUI

extension ContentView {
    // MARK: - 온보딩
    var onboardingView: some View {
      ZStack {
        MoodieBackground(colors: vm.backgroundColors(for: "맑음"))
        VStack(spacing: 22) {
          TabView(selection: $onboardingPage) {
            onboardingPageView(
              title: "Moodie Sky", subtitle: "오늘의 마음을 날씨처럼 가볍게 남겨요.",
              visual: AnyView(moodieLogoMark(size: 172))
            ).tag(0)
            onboardingPageView(
              title: "짧게 고르고, 짧게 적어요", subtitle: "날씨 하나와 한 줄 메모만으로 오늘의 마음을 남길 수 있어요.",
              visual: AnyView(appUsagePreview)
            ).tag(1)
            onboardingPageView(
              title: "하루 기록은 3개까지", subtitle: "기록을 부담으로 만들지 않도록 하루의 중요한 마음만 남겨요.",
              visual: AnyView(limitPreview)
            ).tag(2)
            onboardingPageView(
              title: "다이어리에서 날짜를 눌러요", subtitle: "달력의 날짜를 누르면 그날 남긴 마음 날씨를 모아서 볼 수 있어요.",
              visual: AnyView(calendarTutorialPreview)
            ).tag(3)
            onboardingPageView(
              title: "밀어서 수정하거나 삭제해요", subtitle: "기록을 오른쪽으로 밀면 수정, 왼쪽으로 밀면 삭제할 수 있어요.",
              visual: AnyView(swipeTutorialPreview)
            ).tag(4)
          }
          .tabViewStyle(.page(indexDisplayMode: .always))

          Button {
            if onboardingPage < 4 {
              withAnimation(.spring()) { onboardingPage += 1 }
            } else {
              vm.finishOnboarding()
              showOnboarding = false
            }
          } label: {
            Text(onboardingPage < 4 ? "다음" : "시작하기")
              .fontWeight(.semibold).frame(maxWidth: .infinity).padding()
              .foregroundStyle(.white).background(vm.moodieTint)
              .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
          }
          .padding(.horizontal, 24).padding(.bottom, 18)
        }
      }
    }

    func onboardingPageView(title: String, subtitle: String, visual: AnyView) -> some View {
      VStack(spacing: 26) {
        Spacer()
        visual.frame(maxWidth: .infinity)
        VStack(spacing: 10) {
          Text(title).font(.system(.title, design: .rounded, weight: .bold)).multilineTextAlignment(
            .center)
          Text(subtitle).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            .padding(.horizontal, 28)
        }
        Spacer()
      }.padding()
    }

    // MARK: - 스플래시
    var launchSplashView: some View {
      moodieSplashSurface
    }

    var privacyShieldView: some View {
      moodieSplashSurface
        .allowsHitTesting(true)
    }

    var moodieSplashSurface: some View {
      ZStack {
        MoodieBackground(colors: vm.backgroundColors(for: "맑음"))
        VStack(spacing: 18) {
          moodieLogoMark(size: 128)
          Text("Moodie Sky").font(.system(.title3, design: .rounded, weight: .semibold))
            .foregroundStyle(.primary)
        }
      }.ignoresSafeArea()
    }

    func moodieLogoMark(size: CGFloat) -> some View {
      Image("MoodieMark")
        .resizable().scaledToFit().frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 10)
    }

    // MARK: - 온보딩 프리뷰들
    var appUsagePreview: some View {
      VStack(alignment: .leading, spacing: 14) {
        Text("오늘 마음의 날씨").font(.headline)
        HStack {
          ForEach(vm.weathers.prefix(3), id: \.0) { weather in
            VStack {
              Text(weather.1).font(.title)
              Text(weather.0).font(.caption2)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
          }
        }
        Text("오늘은 구름이 많았지만 괜찮았어요")
          .font(.subheadline).padding().frame(maxWidth: .infinity, alignment: .leading)
          .background(.thinMaterial)
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
      .padding().frame(width: 310)
      .background(.regularMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(
          Color.primary.opacity(0.05), lineWidth: 1))
    }

    var limitPreview: some View {
      HStack(spacing: 12) {
        ForEach(0..<3, id: \.self) { index in
          Text(["☀️", "☁️", "🌧️"][index]).font(.system(size: 34))
            .frame(width: 70, height: 70).background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(
                Color.primary.opacity(0.05), lineWidth: 1))
        }
      }
    }

    var calendarTutorialPreview: some View {
      LazyVGrid(columns: Array(repeating: GridItem(.fixed(42), spacing: 8), count: 5), spacing: 8) {
        ForEach(1...15, id: \.self) { day in
          VStack(spacing: 4) {
            Text("\(day)").font(.caption).fontWeight(.bold)
            Text(day == 7 ? "☁️" : day == 12 ? "🌈" : "").font(.caption)
          }
          .frame(width: 42, height: 52)
          .background(day == 12 ? vm.moodieTint.opacity(0.16) : Color.primary.opacity(0.04))
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(
              day == 12 ? vm.moodieTint.opacity(0.45) : Color.clear, lineWidth: 1))
        }
      }
      .padding().background(.regularMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(
          Color.primary.opacity(0.05), lineWidth: 1))
    }

    var swipeTutorialPreview: some View {
      HStack {
        Label("수정", systemImage: "pencil").font(.caption).fontWeight(.bold).foregroundStyle(.white)
          .padding(.horizontal, 14).padding(.vertical, 12).background(.blue)
          .clipShape(RoundedRectangle(cornerRadius: 12))
        HStack {
          Text("☁️")
          Text("오후엔 조금 흐렸어요").font(.subheadline)
          Spacer()
        }
        .padding().frame(width: 190).background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        Label("삭제", systemImage: "trash").font(.caption).fontWeight(.bold).foregroundStyle(.white)
          .padding(.horizontal, 14).padding(.vertical, 12).background(.red)
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
}
