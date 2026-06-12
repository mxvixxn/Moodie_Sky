import SwiftData
import SwiftUI

extension ContentView {
    // MARK: - 설정 탭
    var settingsView: some View {
      NavigationStack {
        ZStack {
          MoodieBackground(colors: vm.backgroundColors())
          ScrollView {
            VStack(alignment: .leading, spacing: 12) {
              Text("설정")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .padding(.top, 8)
                .padding(.bottom, 4)

              VStack(spacing: 10) {
                settingsCategoryRow(
                  route: .general,
                  icon: "slider.horizontal.3",
                  title: "일반",
                  subtitle: "앱 상태와 기본 정보를 확인해요"
                )
                settingsCategoryRow(
                  route: .notifications,
                  icon: "bell",
                  title: "알림",
                  subtitle: vm.isReminderEnabled ? "매일 알림 켜짐" : "매일 알림 꺼짐"
                )
                settingsCategoryRow(
                  route: .security,
                  icon: "lock",
                  title: "보안",
                  subtitle: vm.hasPasscode ? "앱 암호 켜짐" : "앱 암호 꺼짐"
                )
                settingsCategoryRow(
                  route: .data,
                  icon: "externaldrive",
                  title: "데이터 관리",
                  subtitle: "백업 내보내기와 초기화를 관리해요"
                )
              }

              settingsAppInfoFooter
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
          }
        }
        .navigationDestination(for: SettingsRoute.self) { route in
          settingsDetailView(for: route)
        }
      }
    }

    func settingsCategoryRow(
      route: SettingsRoute,
      icon: String,
      title: String,
      subtitle: String
    ) -> some View {
      NavigationLink(value: route) {
        HStack(spacing: 14) {
          MoodieIconBadge(systemName: icon, color: vm.moodieTint)
          VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
          }
          Spacer()
          Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.tertiary)
        }
        .moodieCard(cornerRadius: vm.controlCornerRadius)
      }
      .buttonStyle(.plain)
    }

    var settingsAppInfoFooter: some View {
      VStack(spacing: 6) {
        Text("Moodie Sky")
          .font(.system(.caption, design: .rounded, weight: .semibold))
          .foregroundStyle(.secondary)
        Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
      .frame(maxWidth: .infinity)
      .padding(.top, 20)
    }

    @ViewBuilder
    func settingsDetailView(for route: SettingsRoute) -> some View {
      switch route {
      case .general:
        settingsDetailContainer(title: "일반") {
          generalSettingsCard
          tutorialReplayButton
        }
      case .notifications:
        settingsDetailContainer(title: "알림") {
          reminderSettingsCard
        }
      case .security:
        settingsDetailContainer(title: "보안") {
          securityStatusDashboard
          privacySettingsCard
        }
      case .data:
        settingsDetailContainer(title: "데이터 관리") {
          dataSummaryCard
          backupSettingsCard
          dataImportButton
          dataDeleteButton
        }
      }
    }

    func settingsDetailContainer<Content: View>(
      title: String,
      @ViewBuilder content: () -> Content
    ) -> some View {
      ZStack {
        MoodieBackground(colors: vm.backgroundColors())
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            content()
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
        }
      }
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.large)
    }
    var generalSettingsCard: some View {
      VStack(alignment: .leading, spacing: 14) {
        Label("기본 사용", systemImage: "slider.horizontal.3")
          .fontWeight(.semibold)

        settingsMenuRow(
          icon: "rectangle.stack",
          title: "시작 화면",
          subtitle: "앱을 열었을 때 먼저 보여줄 탭을 선택해요.",
          currentValue: vm.preferredStartTab.label,
          options: Array(AppStartTab.allCases),
          selection: vm.preferredStartTab,
          optionTitle: { $0.label },
          onSelect: { vm.setPreferredStartTab($0) }
        )

        settingsMenuRow(
          icon: "calendar",
          title: "날짜 표시",
          subtitle: dateDisplayDescription(for: vm.dateDisplayStyle),
          currentValue: vm.dateDisplayStyle.label,
          options: Array(MoodDateDisplayStyle.allCases),
          selection: vm.dateDisplayStyle,
          optionTitle: { $0.label },
          onSelect: { vm.setDateDisplayStyle($0) }
        )

        settingsMenuRow(
          icon: "circle.lefthalf.filled",
          title: "앱 테마",
          subtitle: appThemeDescription(for: vm.appTheme),
          currentValue: vm.appTheme.label,
          options: Array(MoodAppTheme.allCases),
          selection: vm.appTheme,
          optionTitle: { $0.label },
          onSelect: { vm.setAppTheme($0) }
        )

        settingsMenuRow(
          icon: "cloud.sun",
          title: "기본 날씨",
          subtitle: "새 기록을 시작할 때 먼저 선택될 날씨예요.",
          currentValue: "\(vm.weathers.first { $0.0 == vm.defaultWeather }?.1 ?? "☀️") \(vm.defaultWeather)",
          options: vm.weathers.map(\.0),
          selection: vm.defaultWeather,
          optionTitle: { weatherName in
            let emoji = vm.weathers.first { $0.0 == weatherName }?.1 ?? "☀️"
            return "\(emoji) \(weatherName)"
          },
          onSelect: { vm.setDefaultWeather($0) }
        )
      }
      .moodieCard(cornerRadius: vm.controlCornerRadius)
    }

    func settingsMenuRow<Option: Hashable>(
      icon: String,
      title: String,
      subtitle: String,
      currentValue: String,
      options: [Option],
      selection: Option,
      optionTitle: @escaping (Option) -> String,
      onSelect: @escaping (Option) -> Void
    ) -> some View {
      Menu {
        ForEach(options, id: \.self) { option in
          Button {
            onSelect(option)
          } label: {
            HStack {
              if option == selection {
                Image(systemName: "checkmark")
              }
              Text(optionTitle(option))
            }
          }
        }
      } label: {
        HStack(spacing: 12) {
          Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(vm.moodieTint)
            .frame(width: 22)

          VStack(alignment: .leading, spacing: 2) {
            Text(title)
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(.primary)
            Text(subtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }

          Spacer(minLength: 10)

          HStack(spacing: 5) {
            Text(currentValue)
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .minimumScaleFactor(0.82)
            Image(systemName: "chevron.up.chevron.down")
              .font(.caption2)
              .fontWeight(.bold)
              .foregroundStyle(.quaternary)
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .moodieInsetSurface(cornerRadius: 14, tint: vm.moodieTint)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
      .buttonStyle(.plain)
    }

    func dateDisplayDescription(for style: MoodDateDisplayStyle) -> String {
      switch style {
      case .korean: return "예: 2026년 5월 15일처럼 자연스럽게 표시해요."
      case .numeric: return "예: 2026.05.15처럼 숫자로 정리해요."
      case .compact: return "예: 5.15처럼 짧고 가볍게 보여줘요."
      }
    }

    func appThemeDescription(for theme: MoodAppTheme) -> String {
      switch theme {
      case .system: return "기기의 밝은/어두운 모드 설정을 따라가요."
      case .light: return "항상 밝은 화면으로 유지해요."
      case .dark: return "항상 어두운 화면으로 유지해요."
      }
    }

    func lockGraceLabel(for interval: TimeInterval) -> String {
      vm.lockGraceOptions.first { $0.seconds == interval }?.label ?? "\(Int(interval))초"
    }

    func passcodeLockoutLabel(for duration: TimeInterval) -> String {
      vm.passcodeLockoutOptions.first { $0.seconds == duration }?.label ?? "\(Int(duration))초"
    }

    var tutorialReplayButton: some View {
      Button {
        onboardingPage = 0
        showOnboarding = true
      } label: {
        HStack(spacing: 15) {
          MoodieIconBadge(systemName: "questionmark.circle", color: vm.moodieTint)
          VStack(alignment: .leading, spacing: 3) {
            Text("튜토리얼 다시 보기").fontWeight(.semibold)
            Text("기록과 다이어리 사용법을 다시 볼 수 있어요").font(.caption).foregroundStyle(.secondary)
          }
          Spacer()
          Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .moodieCard(cornerRadius: vm.controlCornerRadius)
      }.buttonStyle(.plain)
    }

    var backupSettingsCard: some View {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 15) {
          MoodieIconBadge(systemName: "square.and.arrow.up", color: vm.moodieTint)
          VStack(alignment: .leading, spacing: 3) {
            Text("백업 파일").fontWeight(.semibold)
            Text("CSV, JSON 또는 암호화 백업으로 저장해요")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Spacer()
        }

        Button {
          requestBackupExport()
        } label: {
          HStack {
            Label("내보내기", systemImage: "square.and.arrow.up")
              .fontWeight(.semibold)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
          }
          .moodieSecondaryControl()
        }
        .buttonStyle(.plain)

        if let lockoutMessage = vm.passcodeLockoutMessage {
          Text(lockoutMessage).font(.caption).foregroundStyle(.red)
        }
      }
      .moodieCard(cornerRadius: vm.controlCornerRadius)
    }
    var reminderSettingsCard: some View {
      VStack(alignment: .leading, spacing: 14) {
        Toggle(
          isOn: Binding(
            get: { vm.isReminderEnabled },
            set: { vm.setReminderEnabled($0) }
          )
        ) {
          Label("마음 날씨 알림", systemImage: "bell").fontWeight(.semibold)
        }
        .tint(vm.moodieTint)

        DatePicker(
          "알림 시간",
          selection: Binding(
            get: { vm.reminderTime },
            set: { vm.updateReminderTime($0) }
          ),
          displayedComponents: .hourAndMinute
        )
        .disabled(!vm.isReminderEnabled)

        VStack(alignment: .leading, spacing: 8) {
          Text("알림 요일").font(.subheadline).fontWeight(.semibold)
          HStack(spacing: 6) {
            ForEach(Array(vm.daysOfWeek.enumerated()), id: \.offset) { index, day in
              let weekday = index + 1
              Button {
                vm.toggleReminderWeekday(weekday)
              } label: {
                Text(day.prefix(1))
                  .font(.caption)
                  .fontWeight(.bold)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 9)
                  .moodieInsetSurface(
                    cornerRadius: 10,
                    tint: vm.moodieTint,
                    isActive: vm.selectedReminderWeekdays.contains(weekday)
                  )
              }
              .buttonStyle(.plain)
            }
          }
        }

        settingsMenuRow(
          icon: "text.bubble",
          title: "알림 문구",
          subtitle: "매일 마음 날씨를 묻는 문장의 분위기를 정해요.",
          currentValue: vm.reminderToneStyle.label,
          options: Array(ReminderToneStyle.allCases),
          selection: vm.reminderToneStyle,
          optionTitle: { $0.label },
          onSelect: { vm.setReminderToneStyle($0) }
        )

        Toggle(
          "오늘 기록했으면 알림 생략",
          isOn: Binding(
            get: { vm.skipsReminderAfterTodayEntry },
            set: { vm.setSkipsReminderAfterTodayEntry($0) }
          )
        )
        .tint(vm.moodieTint)

        Toggle(
          "조용한 시간",
          isOn: Binding(
            get: { vm.quietHoursEnabled },
            set: { vm.setQuietHoursEnabled($0) }
          )
        )
        .tint(vm.moodieTint)

        if vm.quietHoursEnabled {
          DatePicker("시작", selection: Binding(get: { vm.quietHoursStart }, set: { vm.updateQuietHoursStart($0) }), displayedComponents: .hourAndMinute)
          DatePicker("끝", selection: Binding(get: { vm.quietHoursEnd }, set: { vm.updateQuietHoursEnd($0) }), displayedComponents: .hourAndMinute)
        }

        Divider().opacity(0.45)

        Toggle(
          "백업 리마인더",
          isOn: Binding(
            get: { vm.backupReminderEnabled },
            set: { vm.setBackupReminderEnabled($0) }
          )
        )
        .tint(vm.moodieTint)

        Stepper("백업 알림 간격: \(vm.backupReminderDays)일", value: Binding(get: { vm.backupReminderDays }, set: { vm.setBackupReminderDays($0) }), in: 7...90, step: 7)
          .disabled(!vm.backupReminderEnabled)
      }
      .moodieCard(cornerRadius: vm.controlCornerRadius)
    }
    var securityStatusDashboard: some View {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 15) {
          MoodieIconBadge(systemName: "shield.checkered", color: vm.moodieTint)
          VStack(alignment: .leading, spacing: 3) {
            Text("현재 보호 상태").fontWeight(.semibold)
            Text("개인 기록을 지키는 설정을 한눈에 확인해요")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Spacer()
        }

        VStack(spacing: 9) {
          securityStatusRow(
            icon: "lock.fill",
            title: "앱 암호",
            isEnabled: vm.hasPasscode,
            enabledText: "켜짐",
            disabledText: "꺼짐"
          )
          securityStatusRow(
            icon: "faceid",
            title: "Face ID",
            isEnabled: vm.isFaceIDEnabled,
            enabledText: "켜짐",
            disabledText: vm.hasPasscode ? "꺼짐" : "암호 필요"
          )
          securityStatusRow(
            icon: "rectangle.on.rectangle.slash",
            title: "미리보기 보호",
            isEnabled: vm.obscuresAppSwitcher,
            enabledText: "켜짐",
            disabledText: "꺼짐"
          )
          securityStatusRow(
            icon: "lock.doc.fill",
            title: "암호화 백업",
            isEnabled: vm.hasPasscode,
            enabledText: "사용 가능",
            disabledText: "암호 필요"
          )
        }
      }
      .moodieCard(cornerRadius: vm.controlCornerRadius)
    }

    func securityStatusRow(
      icon: String,
      title: String,
      isEnabled: Bool,
      enabledText: String,
      disabledText: String
    ) -> some View {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(isEnabled ? vm.moodieTint : .secondary)
          .frame(width: 24, height: 24)
        Text(title)
          .font(.subheadline)
          .fontWeight(.semibold)
        Spacer()
        Text(isEnabled ? enabledText : disabledText)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(isEnabled ? vm.moodieTint : .secondary)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background((isEnabled ? vm.moodieTint : Color.secondary).opacity(0.10))
          .clipShape(Capsule())
      }
      .padding(.vertical, 2)
    }

    var privacySettingsCard: some View {
      VStack(alignment: .leading, spacing: 14) {
        HStack {
          Label("앱 암호", systemImage: "lock").fontWeight(.semibold)
          Spacer()
          Text(vm.hasPasscode ? "켜짐" : "꺼짐")
            .font(.caption).fontWeight(.semibold)
            .foregroundStyle(vm.hasPasscode ? vm.moodieTint : .secondary)
        }

        Button {
          passcodeSetupDigitCount = vm.passcodeDigitCount
          newPasscode = ""
          confirmPasscode = ""
          showPasscodeSetup = true
        } label: {
          HStack {
            Text(vm.hasPasscode ? "암호 변경" : "암호 만들기").fontWeight(.semibold)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
          }
          .moodieSecondaryControl()
        }
        .buttonStyle(.plain)

        Toggle(
          isOn: Binding(
            get: { vm.isFaceIDEnabled },
            set: { vm.setFaceIDEnabled($0) }
          )
        ) {
          Label("Face ID로 바로 해제", systemImage: "faceid").fontWeight(.semibold)
        }
        .disabled(!vm.hasPasscode)
        .tint(vm.moodieTint)

        Toggle(
          "앱 전환 화면 가리기",
          isOn: Binding(
            get: { vm.obscuresAppSwitcher },
            set: { vm.setObscuresAppSwitcher($0) }
          )
        )
        .tint(vm.moodieTint)

        settingsMenuRow(
          icon: "timer",
          title: "앱을 떠난 뒤 다시 잠그기",
          subtitle: "앱을 잠깐 벗어났을 때 잠금까지 기다릴 시간을 정해요.",
          currentValue: lockGraceLabel(for: vm.lockGraceInterval),
          options: vm.lockGraceOptions.map(\.seconds),
          selection: vm.lockGraceInterval,
          optionTitle: { lockGraceLabel(for: $0) },
          onSelect: { vm.updateLockGraceInterval($0) }
        )
        .disabled(!vm.hasPasscode)

        settingsMenuRow(
          icon: "exclamationmark.lock",
          title: "암호 실패 후 입력 제한",
          subtitle: "암호를 여러 번 틀렸을 때 다시 시도할 수 있는 시간을 정해요.",
          currentValue: passcodeLockoutLabel(for: vm.passcodeLockoutDuration),
          options: vm.passcodeLockoutOptions.map(\.seconds),
          selection: vm.passcodeLockoutDuration,
          optionTitle: { passcodeLockoutLabel(for: $0) },
          onSelect: { vm.updatePasscodeLockoutDuration($0) }
        )
        .disabled(!vm.hasPasscode)

        Text("내보내기와 데이터 삭제는 항상 Face ID 또는 앱 암호 확인 후 진행돼요.")
          .font(.caption).foregroundStyle(.secondary)

        if vm.hasPasscode {
          Button(role: .destructive) {
            requestPasscodeRemoval()
          } label: {
            Label("암호 삭제", systemImage: "trash")
              .font(.caption).fontWeight(.semibold)
          }
        }

        if !vm.authErrorMessage.isEmpty {
          Text(vm.authErrorMessage).font(.caption).foregroundStyle(.red)
        }
      }
      .moodieCard(cornerRadius: vm.controlCornerRadius)
    }
    var dataSummaryCard: some View {
      VStack(alignment: .leading, spacing: 12) {
        Label("데이터 요약", systemImage: "chart.bar.doc.horizontal")
          .fontWeight(.semibold)
        Text(vm.dataSummaryText)
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Text(vm.backupSummaryText)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .moodieCard(cornerRadius: vm.controlCornerRadius)
    }

    var dataImportButton: some View {
      Button {
        showBackupImport = true
      } label: {
        HStack(spacing: 15) {
          MoodieIconBadge(systemName: "square.and.arrow.down", color: vm.moodieTint)
          VStack(alignment: .leading, spacing: 3) {
            Text("백업 가져오기").fontWeight(.semibold)
            Text("CSV 또는 JSON 백업을 현재 기록에 합쳐요").font(.caption).foregroundStyle(.secondary)
          }
          Spacer()
        }
        .moodieCard(cornerRadius: vm.controlCornerRadius)
      }
      .buttonStyle(.plain)
    }

    var dataDeleteButton: some View {
      VStack(alignment: .leading, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Label("위험 작업", systemImage: "exclamationmark.triangle")
            .fontWeight(.semibold)
            .foregroundStyle(.red)
          Text("삭제 전 앱 암호를 확인하지만, 완료된 삭제는 되돌릴 수 없어요.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        VStack(spacing: 8) {
          destructiveSettingsRow(
            title: "오늘 기록 삭제",
            subtitle: "오늘 남긴 기록만 정리해요.",
            icon: "calendar.badge.minus"
          ) {
            requestDataDelete(.today)
          }

          destructiveSettingsRow(
            title: "이번 달 기록 삭제",
            subtitle: "이번 달 기록을 한 번에 지워요.",
            icon: "calendar"
          ) {
            requestDataDelete(.month)
          }

          destructiveSettingsRow(
            title: "모든 데이터 초기화",
            subtitle: "기록과 설정 데이터를 모두 초기 상태로 돌려요.",
            icon: "trash.fill"
          ) {
            requestDataDelete(.all)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .moodieCard(cornerRadius: vm.controlCornerRadius)
    }

    func destructiveSettingsRow(
      title: String,
      subtitle: String,
      icon: String,
      action: @escaping () -> Void
    ) -> some View {
      Button(role: .destructive, action: action) {
        HStack(spacing: 12) {
          Image(systemName: icon)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.red)
            .frame(width: 34, height: 34)
            .moodieInsetSurface(cornerRadius: 10, tint: .red, isActive: true)

          VStack(alignment: .leading, spacing: 2) {
            Text(title)
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(.primary)
            Text(subtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)
          }

          Spacer(minLength: 8)

          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(12)
        .moodieInsetSurface(cornerRadius: 14, tint: .red)
      }
      .buttonStyle(.plain)
    }

    var passcodeSetupView: some View {
      NavigationStack {
        ZStack {
          MoodieBackground(colors: vm.backgroundColors(for: "구름"))
          VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
              Text(vm.hasPasscode ? "암호 변경" : "암호 만들기")
                .font(.system(.title, design: .rounded, weight: .bold))
              Text("\(passcodeSetupDigitCount)자리 숫자 암호를 설정해주세요.")
                .font(.subheadline).foregroundStyle(.secondary)
            }

            Picker("암호 길이", selection: $passcodeSetupDigitCount) {
              Text("4자리").tag(4)
              Text("6자리").tag(6)
            }
            .pickerStyle(.segmented)
            .onChange(of: passcodeSetupDigitCount) { _, _ in
              newPasscode = ""
              confirmPasscode = ""
            }

            SecureField("새 암호", text: $newPasscode)
              .keyboardType(.numberPad)
              .textContentType(.oneTimeCode)
              .padding()
              .moodieInsetSurface(
                cornerRadius: vm.controlCornerRadius,
                tint: vm.moodieTint,
                isActive: newPasscode.count == passcodeSetupDigitCount
              )
              .onChange(of: newPasscode) { _, value in
                newPasscode = vm.limitedDigits(value, count: passcodeSetupDigitCount)
              }

            SecureField("암호 확인", text: $confirmPasscode)
              .keyboardType(.numberPad)
              .textContentType(.oneTimeCode)
              .padding()
              .moodieInsetSurface(
                cornerRadius: vm.controlCornerRadius,
                tint: vm.moodieTint,
                isActive: confirmPasscode.count == passcodeSetupDigitCount
              )
              .onChange(of: confirmPasscode) { _, value in
                confirmPasscode = vm.limitedDigits(value, count: passcodeSetupDigitCount)
              }

            if !vm.authErrorMessage.isEmpty {
              Text(vm.authErrorMessage).font(.caption).foregroundStyle(.red)
            }

            Button {
              if vm.setPasscode(
                newPasscode, confirmation: confirmPasscode, digitCount: passcodeSetupDigitCount)
              {
                recoveryKeyToShow = vm.latestRecoveryKey
                showPasscodeSetup = false
                showRecoveryKeyNotice = !recoveryKeyToShow.isEmpty
                newPasscode = ""
                confirmPasscode = ""
              }
            } label: {
              Text("저장")
                .fontWeight(.semibold).frame(maxWidth: .infinity).padding()
                .foregroundStyle(.white)
                .background(
                  newPasscode.count == passcodeSetupDigitCount
                    && confirmPasscode.count == passcodeSetupDigitCount
                    ? vm.moodieTint : Color.secondary.opacity(0.35)
                )
                .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
            }
            .disabled(
              newPasscode.count != passcodeSetupDigitCount
                || confirmPasscode.count != passcodeSetupDigitCount)
            Spacer()
          }
          .padding()
        }
        .navigationTitle("앱 암호")
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("취소") { showPasscodeSetup = false }
          }
        }
      }
    }

    func requestDataDelete(_ scope: DataDeleteScope) {
      guard vm.hasPasscode else {
        vm.authErrorMessage = "데이터 삭제를 하려면 먼저 앱 암호를 만들어주세요."
        passcodeSetupDigitCount = vm.passcodeDigitCount
        newPasscode = ""
        confirmPasscode = ""
        showPasscodeSetup = true
        return
      }

      pendingDeleteScope = scope
      deleteAuthPasscode = ""
      vm.refreshPasscodeLockout()
      guard !vm.isPasscodeTemporarilyLocked else {
        showDeleteAuth = true
        return
      }

      if vm.isFaceIDEnabled {
        vm.authenticateProtectedActionWithBiometrics { success in
          if success {
            performPendingDataDelete()
          } else {
            showDeleteAuth = true
          }
        }
      } else {
        showDeleteAuth = true
      }
    }

    func performPendingDataDelete() {
      showDeleteAuth = false
      deleteAuthPasscode = ""
      switch pendingDeleteScope {
      case .today:
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? Date()
        vm.deleteEntries(in: DateInterval(start: start, end: end))
      case .month:
        if let interval = Calendar.current.dateInterval(of: .month, for: Date()) {
          vm.deleteEntries(in: interval)
        }
      case .all:
        vm.showAllDeleteAlert = true
      }
    }

    func requestBackupExport() {
      guard vm.hasPasscode else {
        vm.authErrorMessage = "백업을 내보내려면 먼저 앱 암호를 만들어주세요."
        passcodeSetupDigitCount = vm.passcodeDigitCount
        newPasscode = ""
        confirmPasscode = ""
        showPasscodeSetup = true
        return
      }
      backupFormatSelectionInProgress = false
      showBackupFormatOptions = true
    }

    func chooseBackupExportFormat(_ format: BackupExportFormat) {
      backupFormatSelectionInProgress = true
      showBackupFormatOptions = false
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
        startBackupExport(format: format)
      }
    }

    func startBackupExport(format: BackupExportFormat) {
      backupExportFormat = format
      backupAuthPasscode = ""
      backupEncryptionPassword = ""
      backupEncryptionConfirmation = ""
      vm.refreshPasscodeLockout()
      guard !vm.isPasscodeTemporarilyLocked else {
        showBackupAuth = true
        return
      }

      if format == .encryptedJSON {
        if vm.isFaceIDEnabled {
          vm.authenticateProtectedActionWithBiometrics { success in
            if success {
              showBackupEncryptionSetup = true
            } else {
              showBackupAuth = true
            }
          }
        } else {
          showBackupAuth = true
        }
        return
      }

      if vm.isFaceIDEnabled {
        vm.prepareBackupExportWithBiometrics(format: format) { url in
          if let url {
            presentBackupShare(url)
          } else {
            showBackupAuth = true
          }
        }
      } else {
        showBackupAuth = true
      }
    }

    var backupFormatOptionsView: some View {
      ZStack {
        MoodieBackground(colors: vm.backgroundColors(for: "구름"))
        VStack(alignment: .leading, spacing: 16) {
          Capsule()
            .fill(Color.primary.opacity(0.14))
            .frame(width: 42, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)

          VStack(alignment: .leading, spacing: 4) {
            Text("내보내기 형식")
              .font(.system(.title3, design: .rounded, weight: .bold))
            Text("백업으로 저장할 파일 형식을 선택해주세요.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          VStack(spacing: 10) {
            backupFormatButton(title: "CSV", subtitle: "스프레드시트에서 보기 좋아요.", icon: "tablecells", format: .csv)
            backupFormatButton(title: "JSON", subtitle: "앱 데이터 복원과 보관에 적합해요.", icon: "doc.text", format: .json)
            backupFormatButton(title: "암호화 백업", subtitle: "암호로 보호된 Moodie Sky 백업 파일이에요.", icon: "lock.doc", format: .encryptedJSON)
          }
        }
        .padding(20)
      }
    }

    func backupFormatButton(title: String, subtitle: String, icon: String, format: BackupExportFormat) -> some View {
      Button {
        chooseBackupExportFormat(format)
      } label: {
        HStack(spacing: 12) {
          Image(systemName: icon)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(vm.moodieTint)
            .frame(width: 36, height: 36)
            .background(vm.moodieTint.opacity(0.12))
            .clipShape(Circle())
          VStack(alignment: .leading, spacing: 2) {
            Text(title)
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(.primary)
            Text(subtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          Spacer()
          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(12)
        .moodieInsetSurface(cornerRadius: vm.controlCornerRadius, tint: vm.moodieTint)
      }
      .buttonStyle(.plain)
    }

    func requestBackupImport(from url: URL) {
      guard vm.hasPasscode else {
        vm.authErrorMessage = "백업을 가져오려면 먼저 앱 암호를 만들어주세요."
        passcodeSetupDigitCount = vm.passcodeDigitCount
        newPasscode = ""
        confirmPasscode = ""
        showPasscodeSetup = true
        return
      }

      pendingBackupImportURL = url
      // 이전 가져오기에서 남은 암호를 재사용하면 암호 입력 화면이 생략된 채 조용히 실패함
      pendingBackupImportPassword = nil
      backupImportAuthPasscode = ""
      vm.refreshPasscodeLockout()
      guard !vm.isPasscodeTemporarilyLocked else {
        showBackupImportAuth = true
        return
      }

      if vm.isFaceIDEnabled {
        vm.authenticateProtectedActionWithBiometrics { success in
          if success {
            performBackupImport()
          } else {
            showBackupImportAuth = true
          }
        }
      } else {
        showBackupImportAuth = true
      }
    }

    func performBackupImport() {
      guard let url = pendingBackupImportURL else { return }
      showBackupImportAuth = false
      backupImportAuthPasscode = ""
      if url.pathExtension.lowercased() == "moodieskybackup", pendingBackupImportPassword == nil {
        encryptedBackupImportPassword = ""
        showEncryptedBackupImportPassword = true
        return
      }
      prepareBackupImportPreview()
    }

    func prepareBackupImportPreview() {
      guard let url = pendingBackupImportURL else { return }
      if let preview = vm.backupImportPreview(from: url, backupPassword: pendingBackupImportPassword) {
        backupImportPreview = preview
      }
    }

    func finishBackupImport() {
      guard let url = pendingBackupImportURL else { return }
      vm.importBackup(from: url, backupPassword: pendingBackupImportPassword)
      backupImportPreview = nil
      pendingBackupImportURL = nil
      pendingBackupImportPassword = nil
      encryptedBackupImportPassword = ""
    }

    var backupAuthView: some View {
      NavigationStack {
        ZStack {
          MoodieBackground(colors: vm.backgroundColors(for: "구름"))
          VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
              Text("백업 내보내기")
                .font(.system(.title, design: .rounded, weight: .bold))
              Text("개인 기록이 담긴 파일이라 앱 암호를 한 번 더 확인해요.")
                .font(.subheadline).foregroundStyle(.secondary)
            }

            SecureField("앱 암호", text: $backupAuthPasscode)
              .keyboardType(.numberPad)
              .textContentType(.oneTimeCode)
              .padding()
              .moodieInsetSurface(
                cornerRadius: vm.controlCornerRadius,
                tint: vm.moodieTint,
                isActive: backupAuthPasscode.count == vm.passcodeDigitCount
              )
              .onChange(of: backupAuthPasscode) { _, value in
                backupAuthPasscode = vm.limitedDigits(value, count: vm.passcodeDigitCount)
              }
              .disabled(vm.isPasscodeTemporarilyLocked)

            if vm.isFaceIDEnabled {
              Button {
                if backupExportFormat == .encryptedJSON {
                  vm.authenticateProtectedActionWithBiometrics { success in
                    guard success else { return }
                    showBackupAuth = false
                    showBackupEncryptionSetup = true
                  }
                } else {
                  vm.prepareBackupExportWithBiometrics(format: backupExportFormat) { url in
                    guard let url else { return }
                    presentBackupShare(url)
                  }
                }
              } label: {
                Label("Face ID로 확인", systemImage: "faceid")
                  .fontWeight(.semibold)
                  .frame(maxWidth: .infinity)
                  .padding()
                  .moodieInsetSurface(cornerRadius: vm.controlCornerRadius, tint: vm.moodieTint)
              }
              .buttonStyle(.plain)
              .disabled(vm.isPasscodeTemporarilyLocked)
            }

            if let lockoutMessage = vm.passcodeLockoutMessage {
              Text(lockoutMessage).font(.caption).foregroundStyle(.red)
            } else if !vm.authErrorMessage.isEmpty {
              Text(vm.authErrorMessage).font(.caption).foregroundStyle(.red)
            }

            Button {
              if backupExportFormat == .encryptedJSON {
                guard vm.validatePasscodeForProtectedAction(backupAuthPasscode) else {
                  backupAuthPasscode = ""
                  return
                }
                showBackupAuth = false
                showBackupEncryptionSetup = true
              } else {
                guard let url = vm.prepareBackupExport(passcode: backupAuthPasscode, format: backupExportFormat) else { return }
                presentBackupShare(url)
              }
            } label: {
              Text("내보내기")
                .fontWeight(.semibold).frame(maxWidth: .infinity).padding()
                .foregroundStyle(.white)
                .background(
                  backupAuthPasscode.count == vm.passcodeDigitCount && !vm.isPasscodeTemporarilyLocked
                    ? vm.moodieTint : Color.secondary.opacity(0.35)
                )
                .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
            }
            .disabled(
              backupAuthPasscode.count != vm.passcodeDigitCount || vm.isPasscodeTemporarilyLocked)

            Spacer()
          }
          .padding()
        }
        .navigationTitle("백업")
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("취소") {
              showBackupAuth = false
              backupAuthPasscode = ""
              pendingDeleteAfterBackup = false
            }
          }
        }
      }
    }

    var backupEncryptionSetupView: some View {
      NavigationStack {
        ZStack {
          MoodieBackground(colors: vm.backgroundColors(for: "구름"))
          VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
              Text("암호화 백업")
                .font(.system(.title, design: .rounded, weight: .bold))
              Text("이 암호를 잊으면 백업 파일을 복원할 수 없어요.")
                .font(.subheadline).foregroundStyle(.secondary)
            }
            Text("기준: 8자 이상. 앱 암호와 별개이며, 이 백업 파일을 다시 가져올 때 꼭 필요해요.")
              .font(.caption)
              .foregroundStyle(.secondary)
            SecureField("백업 암호", text: $backupEncryptionPassword)
              .textContentType(.newPassword)
              .padding()
              .moodieInsetSurface(
                cornerRadius: vm.controlCornerRadius,
                tint: vm.moodieTint,
                isActive: backupEncryptionPassword.count >= 8
              )
            SecureField("백업 암호 확인", text: $backupEncryptionConfirmation)
              .textContentType(.newPassword)
              .padding()
              .moodieInsetSurface(
                cornerRadius: vm.controlCornerRadius,
                tint: vm.moodieTint,
                isActive: !backupEncryptionConfirmation.isEmpty
                  && backupEncryptionConfirmation == backupEncryptionPassword
              )
            if !vm.authErrorMessage.isEmpty {
              Text(vm.authErrorMessage).font(.caption).foregroundStyle(.red)
            }
            Button {
              guard backupEncryptionPassword == backupEncryptionConfirmation else {
                vm.authErrorMessage = "백업 암호가 서로 달라요."
                return
              }
              guard let url = vm.prepareAuthenticatedBackupExport(format: .encryptedJSON, backupPassword: backupEncryptionPassword) else { return }
              showBackupEncryptionSetup = false
              backupEncryptionPassword = ""
              backupEncryptionConfirmation = ""
              presentBackupShare(url)
            } label: {
              Text("암호화해서 내보내기")
                .fontWeight(.semibold).frame(maxWidth: .infinity).padding()
                .foregroundStyle(.white)
                .background(backupEncryptionPassword.count >= 8 && backupEncryptionPassword == backupEncryptionConfirmation ? vm.moodieTint : Color.secondary.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
            }
            .disabled(backupEncryptionPassword.count < 8 || backupEncryptionPassword != backupEncryptionConfirmation)
            Spacer()
          }
          .padding(24)
        }
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("취소") {
              showBackupEncryptionSetup = false
              backupEncryptionPassword = ""
              backupEncryptionConfirmation = ""
              pendingDeleteAfterBackup = false
            }
          }
        }
      }
    }

    var backupImportAuthView: some View {
      NavigationStack {
        ZStack {
          MoodieBackground(colors: vm.backgroundColors(for: "구름"))
          VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
              Text("백업 가져오기")
                .font(.system(.title, design: .rounded, weight: .bold))
              Text("기존 기록에 영향을 줄 수 있어 앱 암호를 한 번 더 확인해요.")
                .font(.subheadline).foregroundStyle(.secondary)
            }

            SecureField("앱 암호", text: $backupImportAuthPasscode)
              .keyboardType(.numberPad)
              .textContentType(.oneTimeCode)
              .padding()
              .moodieInsetSurface(
                cornerRadius: vm.controlCornerRadius,
                tint: vm.moodieTint,
                isActive: backupImportAuthPasscode.count == vm.passcodeDigitCount
              )
              .onChange(of: backupImportAuthPasscode) { _, value in
                backupImportAuthPasscode = vm.limitedDigits(value, count: vm.passcodeDigitCount)
              }
              .disabled(vm.isPasscodeTemporarilyLocked)

            if vm.isFaceIDEnabled {
              Button {
                vm.authenticateProtectedActionWithBiometrics { success in
                  guard success else { return }
                  performBackupImport()
                }
              } label: {
                Label("Face ID로 확인", systemImage: "faceid")
                  .fontWeight(.semibold)
                  .frame(maxWidth: .infinity)
                  .padding()
                  .moodieInsetSurface(cornerRadius: vm.controlCornerRadius, tint: vm.moodieTint)
              }
              .buttonStyle(.plain)
              .disabled(vm.isPasscodeTemporarilyLocked)
            }

            if let lockoutMessage = vm.passcodeLockoutMessage {
              Text(lockoutMessage).font(.caption).foregroundStyle(.red)
            } else if !vm.authErrorMessage.isEmpty {
              Text(vm.authErrorMessage).font(.caption).foregroundStyle(.red)
            }

            Button {
              guard vm.validatePasscodeForProtectedAction(backupImportAuthPasscode) else {
                backupImportAuthPasscode = ""
                return
              }
              performBackupImport()
            } label: {
              Text("가져오기")
                .fontWeight(.semibold).frame(maxWidth: .infinity).padding()
                .foregroundStyle(.white)
                .background(
                  backupImportAuthPasscode.count == vm.passcodeDigitCount && !vm.isPasscodeTemporarilyLocked
                    ? vm.moodieTint : Color.secondary.opacity(0.35)
                )
                .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
            }
            .disabled(backupImportAuthPasscode.count != vm.passcodeDigitCount || vm.isPasscodeTemporarilyLocked)

            Spacer()
          }
          .padding(24)
        }
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("취소") {
              pendingBackupImportURL = nil
              backupImportAuthPasscode = ""
              showBackupImportAuth = false
            }
          }
        }
      }
    }

    var encryptedBackupImportPasswordView: some View {
      NavigationStack {
        ZStack {
          MoodieBackground(colors: vm.backgroundColors(for: "구름"))
          VStack(alignment: .leading, spacing: 18) {
            Text("암호화 백업 열기")
              .font(.system(.title, design: .rounded, weight: .bold))
            Text("백업을 만들 때 설정한 암호를 입력해주세요.")
              .font(.subheadline).foregroundStyle(.secondary)
            SecureField("백업 암호", text: $encryptedBackupImportPassword)
              .textContentType(.password)
              .padding()
              .moodieInsetSurface(
                cornerRadius: vm.controlCornerRadius,
                tint: vm.moodieTint,
                isActive: !encryptedBackupImportPassword.isEmpty
              )
            if !vm.authErrorMessage.isEmpty {
              Text(vm.authErrorMessage).font(.caption).foregroundStyle(.red)
            }
            Button {
              pendingBackupImportPassword = encryptedBackupImportPassword
              showEncryptedBackupImportPassword = false
              prepareBackupImportPreview()
            } label: {
              Text("미리보기")
                .fontWeight(.semibold).frame(maxWidth: .infinity).padding()
                .foregroundStyle(.white)
                .background(encryptedBackupImportPassword.isEmpty ? Color.secondary.opacity(0.35) : vm.moodieTint)
                .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
            }
            .disabled(encryptedBackupImportPassword.isEmpty)
            Spacer()
          }
          .padding(24)
        }
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("취소") {
              showEncryptedBackupImportPassword = false
              pendingBackupImportURL = nil
              pendingBackupImportPassword = nil
              encryptedBackupImportPassword = ""
            }
          }
        }
      }
    }

    func backupImportPreviewView(_ preview: BackupImportPreview) -> some View {
      NavigationStack {
        ZStack {
          MoodieBackground(colors: vm.backgroundColors(for: "구름"))
          VStack(alignment: .leading, spacing: 16) {
            Text("가져오기 미리보기")
              .font(.system(.title, design: .rounded, weight: .bold))
            VStack(alignment: .leading, spacing: 10) {
              Label("전체 기록 \(preview.totalEntries)개", systemImage: "tray.and.arrow.down")
              Label("새 기록 \(preview.newEntries)개", systemImage: "plus.circle")
              Label("업데이트 \(preview.updatedEntries)개", systemImage: "arrow.triangle.2.circlepath")
              Label("변경 없음 \(preview.unchangedEntries)개", systemImage: "checkmark.circle")
            }
            .moodieCard(cornerRadius: vm.controlCornerRadius)
            Text("가져오기 전 미리 확인한 뒤 기존 기록과 병합해요.")
              .font(.caption).foregroundStyle(.secondary)
            Button { finishBackupImport() } label: {
              Text("가져오기")
                .fontWeight(.semibold).frame(maxWidth: .infinity).padding()
                .foregroundStyle(.white)
                .background(vm.moodieTint)
                .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
            }
            Spacer()
          }
          .padding(24)
        }
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("취소") {
              backupImportPreview = nil
              pendingBackupImportURL = nil
              pendingBackupImportPassword = nil
            }
          }
        }
      }
    }

    var deleteAuthView: some View {
      NavigationStack {
        ZStack {
          MoodieBackground(colors: vm.backgroundColors(for: "폭풍"))
          VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
              Text("삭제 확인")
                .font(.system(.title, design: .rounded, weight: .bold))
              Text("기록 삭제 전 앱 암호를 확인해요.")
                .font(.subheadline).foregroundStyle(.secondary)
            }

            SecureField("앱 암호", text: $deleteAuthPasscode)
              .keyboardType(.numberPad)
              .textContentType(.oneTimeCode)
              .padding()
              .moodieInsetSurface(
                cornerRadius: vm.controlCornerRadius,
                tint: .red,
                isActive: deleteAuthPasscode.count == vm.passcodeDigitCount
              )
              .onChange(of: deleteAuthPasscode) { _, value in
                deleteAuthPasscode = vm.limitedDigits(value, count: vm.passcodeDigitCount)
              }
              .disabled(vm.isPasscodeTemporarilyLocked)

            if let lockoutMessage = vm.passcodeLockoutMessage {
              Text(lockoutMessage).font(.caption).foregroundStyle(.red)
            } else if !vm.authErrorMessage.isEmpty {
              Text(vm.authErrorMessage).font(.caption).foregroundStyle(.red)
            }

            Button(role: .destructive) {
              guard vm.validatePasscodeForProtectedAction(deleteAuthPasscode) else {
                deleteAuthPasscode = ""
                return
              }
              performPendingDataDelete()
            } label: {
              Text("삭제 계속")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(.white)
                .background(
                  deleteAuthPasscode.count == vm.passcodeDigitCount && !vm.isPasscodeTemporarilyLocked
                    ? Color.red : Color.secondary.opacity(0.35)
                )
                .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
            }
            .disabled(deleteAuthPasscode.count != vm.passcodeDigitCount || vm.isPasscodeTemporarilyLocked)

            Spacer()
          }
          .padding()
        }
        .navigationTitle("삭제 인증")
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("취소") {
              showDeleteAuth = false
              deleteAuthPasscode = ""
            }
          }
        }
      }
    }

    func presentBackupShare(_ url: URL) {
      showBackupAuth = false
      backupAuthPasscode = ""
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
        backupShareItem = BackupShareItem(url: url)
      }
    }

    func requestPasscodeRemoval() {
      passcodeRemoveAuthPasscode = ""
      vm.authErrorMessage = ""
      vm.refreshPasscodeLockout()
      guard !vm.isPasscodeTemporarilyLocked else {
        showPasscodeRemoveAuth = true
        return
      }
      if vm.isFaceIDEnabled {
        vm.authenticateProtectedActionWithBiometrics { success in
          if success {
            vm.removePasscode()
          } else {
            showPasscodeRemoveAuth = true
          }
        }
      } else {
        showPasscodeRemoveAuth = true
      }
    }

    var passcodeRemoveAuthView: some View {
      NavigationStack {
        ZStack {
          MoodieBackground(colors: vm.backgroundColors(for: "폭풍"))
          VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
              Text("암호 삭제 확인")
                .font(.system(.title, design: .rounded, weight: .bold))
              Text("앱 암호를 입력하면 잠금이 해제돼요.")
                .font(.subheadline).foregroundStyle(.secondary)
            }

            SecureField("앱 암호", text: $passcodeRemoveAuthPasscode)
              .keyboardType(.numberPad)
              .textContentType(.oneTimeCode)
              .padding()
              .moodieInsetSurface(
                cornerRadius: vm.controlCornerRadius,
                tint: .red,
                isActive: passcodeRemoveAuthPasscode.count == vm.passcodeDigitCount
              )
              .onChange(of: passcodeRemoveAuthPasscode) { _, value in
                passcodeRemoveAuthPasscode = vm.limitedDigits(value, count: vm.passcodeDigitCount)
              }
              .disabled(vm.isPasscodeTemporarilyLocked)

            if vm.isFaceIDEnabled {
              Button {
                vm.authenticateProtectedActionWithBiometrics { success in
                  guard success else { return }
                  showPasscodeRemoveAuth = false
                  vm.removePasscode()
                }
              } label: {
                Label("Face ID로 확인", systemImage: "faceid")
                  .fontWeight(.semibold)
                  .frame(maxWidth: .infinity)
                  .padding()
                  .moodieInsetSurface(cornerRadius: vm.controlCornerRadius, tint: vm.moodieTint)
              }
              .buttonStyle(.plain)
              .disabled(vm.isPasscodeTemporarilyLocked)
            }

            if let lockoutMessage = vm.passcodeLockoutMessage {
              Text(lockoutMessage).font(.caption).foregroundStyle(.red)
            } else if !vm.authErrorMessage.isEmpty {
              Text(vm.authErrorMessage).font(.caption).foregroundStyle(.red)
            }

            Button(role: .destructive) {
              guard vm.validatePasscodeForProtectedAction(passcodeRemoveAuthPasscode) else {
                passcodeRemoveAuthPasscode = ""
                return
              }
              showPasscodeRemoveAuth = false
              vm.removePasscode()
            } label: {
              Text("암호 삭제")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(.white)
                .background(
                  passcodeRemoveAuthPasscode.count == vm.passcodeDigitCount && !vm.isPasscodeTemporarilyLocked
                    ? Color.red : Color.secondary.opacity(0.35)
                )
                .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
            }
            .disabled(
              passcodeRemoveAuthPasscode.count != vm.passcodeDigitCount || vm.isPasscodeTemporarilyLocked)

            Spacer()
          }
          .padding()
        }
        .navigationTitle("보안 설정")
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("취소") {
              showPasscodeRemoveAuth = false
              passcodeRemoveAuthPasscode = ""
              vm.authErrorMessage = ""
            }
          }
        }
      }
    }
}

private struct MoodieSettingsDetailPreview: View {
  let route: SettingsRoute
  let colorScheme: ColorScheme?

  var body: some View {
    NavigationStack {
      ContentView()
        .settingsDetailView(for: route)
    }
    .modelContainer(MoodiePreviewContainer.container)
    .preferredColorScheme(colorScheme)
  }
}

#Preview("Settings - General") {
  MoodieSettingsDetailPreview(route: .general, colorScheme: nil)
}

#Preview("Settings - Notifications") {
  MoodieSettingsDetailPreview(route: .notifications, colorScheme: nil)
}

#Preview("Settings - Security") {
  MoodieSettingsDetailPreview(route: .security, colorScheme: nil)
}

#Preview("Settings - Data") {
  MoodieSettingsDetailPreview(route: .data, colorScheme: nil)
}

#Preview("Settings - Data Dark") {
  MoodieSettingsDetailPreview(route: .data, colorScheme: .dark)
}
