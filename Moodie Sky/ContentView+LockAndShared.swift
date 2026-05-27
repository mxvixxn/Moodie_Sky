import SwiftUI

extension ContentView {
    var lockScreenView: some View {
      ZStack {
        MoodieBackground(colors: vm.backgroundColors(for: "맑음"))
        VStack(spacing: 20) {
          moodieLogoMark(size: 108)
          VStack(spacing: 6) {
            Text("Moodie Sky").font(.system(.title3, design: .rounded, weight: .bold))
            Text(vm.isFaceIDEnabled ? "Face ID를 확인하고 있어요." : "앱 암호를 입력해주세요.")
              .font(.subheadline).foregroundStyle(.secondary)
          }
          passcodeDots.padding(.top, 4)
          lockNumberPad.padding(.top, 4)
          if vm.isFaceIDEnabled {
            Button(action: vm.unlockWithBiometricsIfAvailable) {
              Label("Face ID 다시 시도", systemImage: "faceid")
                .font(.caption).fontWeight(.semibold)
            }
            .buttonStyle(.plain)
          }
          if !vm.authErrorMessage.isEmpty {
            Text(vm.authErrorMessage).font(.caption).foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal)
          }
          Button {
            showForgotPasscodeResetAlert = true
          } label: {
            Text("암호를 잊으셨나요?")
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
          .padding(.top, 2)
        }
        .padding(24)
      }
      .ignoresSafeArea()
      .onAppear { vm.unlockWithBiometricsIfAvailable() }
      .alert("암호를 재설정할까요?", isPresented: $showForgotPasscodeResetAlert) {
        Button("복구키로 재설정") {
          recoveryKeyInput = ""
          recoveryNewPasscode = ""
          recoveryConfirmPasscode = ""
          showRecoveryKeyReset = true
        }
        Button("기록 삭제 후 초기화", role: .destructive) {
          vm.resetLocalDataAndSecurity()
        }
        Button("취소", role: .cancel) {}
      } message: {
        Text("복구키가 있으면 기존 기록을 유지한 채 새 암호를 만들 수 있어요. 복구키가 없으면 보안을 위해 기록과 잠금 정보를 함께 삭제해야 해요.")
      }
    }

    var recoveryKeyResetView: some View {
      NavigationStack {
        ZStack {
          MoodieBackground(colors: vm.backgroundColors(for: "구름"))
          VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
              Text("복구키로 재설정")
                .font(.system(.title, design: .rounded, weight: .bold))
              Text("복구키를 입력하면 기록은 유지하고 앱 암호만 새로 만들 수 있어요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            TextField("복구키", text: $recoveryKeyInput)
              .textInputAutocapitalization(.characters)
              .autocorrectionDisabled()
              .padding()
              .moodieInsetSurface(cornerRadius: vm.controlCornerRadius, tint: vm.moodieTint)

            SecureField("새 암호", text: $recoveryNewPasscode)
              .keyboardType(.numberPad)
              .textContentType(.oneTimeCode)
              .padding()
              .moodieInsetSurface(
                cornerRadius: vm.controlCornerRadius,
                tint: vm.moodieTint,
                isActive: recoveryNewPasscode.count == vm.passcodeDigitCount
              )
              .onChange(of: recoveryNewPasscode) { _, value in
                recoveryNewPasscode = vm.limitedDigits(value, count: vm.passcodeDigitCount)
              }

            SecureField("새 암호 확인", text: $recoveryConfirmPasscode)
              .keyboardType(.numberPad)
              .textContentType(.oneTimeCode)
              .padding()
              .moodieInsetSurface(
                cornerRadius: vm.controlCornerRadius,
                tint: vm.moodieTint,
                isActive: recoveryConfirmPasscode.count == vm.passcodeDigitCount
              )
              .onChange(of: recoveryConfirmPasscode) { _, value in
                recoveryConfirmPasscode = vm.limitedDigits(value, count: vm.passcodeDigitCount)
              }

            if !vm.authErrorMessage.isEmpty {
              Text(vm.authErrorMessage)
                .font(.caption)
                .foregroundStyle(.red)
            }

            Button {
              if vm.resetPasscodeWithRecoveryKey(
                recoveryKeyInput,
                newPasscode: recoveryNewPasscode,
                confirmation: recoveryConfirmPasscode,
                digitCount: vm.passcodeDigitCount
              ) {
                recoveryKeyToShow = vm.latestRecoveryKey
                showRecoveryKeyReset = false
                showRecoveryKeyNotice = !recoveryKeyToShow.isEmpty
                recoveryKeyInput = ""
                recoveryNewPasscode = ""
                recoveryConfirmPasscode = ""
              }
            } label: {
              Text("새 암호 저장")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(.white)
                .background(
                  recoveryKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || recoveryNewPasscode.count != vm.passcodeDigitCount
                    || recoveryConfirmPasscode.count != vm.passcodeDigitCount
                    ? Color.secondary.opacity(0.35) : vm.moodieTint
                )
                .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
            }
            .disabled(
              recoveryKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || recoveryNewPasscode.count != vm.passcodeDigitCount
                || recoveryConfirmPasscode.count != vm.passcodeDigitCount
            )

            Spacer()
          }
          .padding(24)
        }
        .navigationTitle("암호 복구")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("취소") {
              showRecoveryKeyReset = false
              recoveryKeyInput = ""
              recoveryNewPasscode = ""
              recoveryConfirmPasscode = ""
            }
          }
        }
      }
    }

    var recoveryKeyConfirmationView: some View {
      NavigationStack {
        ZStack {
          MoodieBackground(colors: vm.backgroundColors(for: "맑음"))
          VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
              Text("복구키 확인")
                .font(.system(.title, design: .rounded, weight: .bold))
              Text("방금 저장한 복구키를 다시 입력하면 앱 암호와 복구키가 함께 설정돼요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            TextField("복구키 다시 입력", text: $recoveryKeyConfirmationInput)
              .textInputAutocapitalization(.characters)
              .autocorrectionDisabled()
              .padding()
              .moodieInsetSurface(
                cornerRadius: vm.controlCornerRadius,
                tint: vm.moodieTint,
                isActive: !recoveryKeyConfirmationInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              )

            if !vm.authErrorMessage.isEmpty {
              Text(vm.authErrorMessage)
                .font(.caption)
                .foregroundStyle(.red)
            }

            Button {
              if vm.confirmLatestRecoveryKey(recoveryKeyConfirmationInput) {
                showRecoveryKeyConfirmation = false
                recoveryKeyConfirmationInput = ""
                recoveryKeyToShow = ""
              }
            } label: {
              Text("암호 설정 완료")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(.white)
                .background(
                  recoveryKeyConfirmationInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? Color.secondary.opacity(0.35) : vm.moodieTint
                )
                .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
            }
            .disabled(recoveryKeyConfirmationInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Text("완료 전에는 앱 암호와 복구키가 저장되지 않아요.")
              .font(.caption)
              .foregroundStyle(.secondary)

            Spacer()
          }
          .padding(24)
        }
        .navigationTitle("복구키")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("나중에") {
              showRecoveryKeyConfirmation = false
              recoveryKeyConfirmationInput = ""
              recoveryKeyToShow = ""
              vm.cancelPendingPasscodeSetup()
            }
          }
        }
        .interactiveDismissDisabled()
      }
    }

    var passcodeDots: some View {
      HStack(spacing: 12) {
        ForEach(0..<vm.passcodeDigitCount, id: \.self) { index in
          Circle()
            .fill(index < vm.lockPasscodeInput.count ? vm.moodieTint : Color.primary.opacity(0.12))
            .frame(width: 13, height: 13)
            .overlay(
              Circle().stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .animation(
              .spring(response: 0.22, dampingFraction: 0.72), value: vm.lockPasscodeInput.count)
        }
      }
      .frame(maxWidth: .infinity)
      .accessibilityLabel("암호 입력 상태")
    }

    var lockNumberPad: some View {
      VStack(spacing: 12) {
        ForEach([["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]], id: \.self) { row in
          HStack(spacing: 14) {
            ForEach(row, id: \.self) { number in
              lockNumberButton(number)
            }
          }
        }

        HStack(spacing: 14) {
          Color.clear.frame(width: 64, height: 64)
          lockNumberButton("0")
          Button(action: vm.deleteLockPasscodeDigit) {
            Image(systemName: "delete.left")
              .font(.system(size: 20, weight: .semibold))
              .foregroundStyle(.primary.opacity(vm.lockPasscodeInput.isEmpty ? 0.22 : 0.74))
              .frame(width: 64, height: 64)
          }
          .disabled(vm.lockPasscodeInput.isEmpty)
          .buttonStyle(.plain)
          .accessibilityLabel("지우기")
        }
      }
    }

    func lockNumberButton(_ number: String) -> some View {
      Button {
        vm.appendLockPasscodeDigit(number)
      } label: {
        Text(number)
          .font(.system(size: 27, weight: .semibold, design: .rounded))
          .foregroundStyle(.primary)
          .frame(width: 64, height: 64)
          .background(.ultraThinMaterial)
          .background(vm.moodieTint.opacity(0.06))
          .clipShape(Circle())
          .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1))
          .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("숫자 \(number)")
    }

    func emptyStateView(icon: String, title: String, message: String) -> some View {
      VStack(spacing: 10) {
        Image(systemName: icon)
          .font(.system(size: 28, weight: .semibold))
          .foregroundStyle(vm.moodieTint)
          .frame(width: 58, height: 58)
          .moodieInsetSurface(cornerRadius: 29, tint: vm.moodieTint, isActive: true)

        VStack(spacing: 5) {
          Text(title)
            .font(.headline)
            .multilineTextAlignment(.center)
          Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .frame(maxWidth: .infinity)
      .moodieCard(cornerRadius: vm.cardCornerRadius)
    }

    // MARK: - 공통 컴포넌트
    var todaySummaryCard: some View {
      HStack(spacing: 14) {
        Text(vm.todaySummaryEmoji)
          .font(.system(size: 34))
          .frame(width: 58, height: 58)
          .moodieInsetSurface(
            cornerRadius: 29,
            tint: vm.accentColor(for: vm.selectedWeather),
            isActive: true
          )

        VStack(alignment: .leading, spacing: 5) {
          Text(vm.todaySummaryTitle)
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true)
          Text(vm.todaySummaryDetail)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 8)
      }
      .padding(15)
      .moodieInsetSurface(
        cornerRadius: vm.cardCornerRadius,
        tint: vm.accentColor(for: vm.selectedWeather),
        isActive: true
      )
    }

    var weatherSelector: some View {
      HStack(spacing: 8) {
        ForEach(vm.weathers, id: \.0) { w in
          let isSelected = vm.selectedWeather == w.0
          Button {
            vm.selectedWeather = w.0
            vm.selectedEmoji = w.1
            vm.triggerHaptic(.light)
          } label: {
            VStack(spacing: 4) {
              Text(w.1).font(.system(size: isSelected ? 30 : 27))
                .frame(maxWidth: .infinity)
              Text(w.0).font(.caption2)
                .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, isSelected ? 12 : 10)
            .moodieInsetSurface(
              cornerRadius: 13,
              tint: vm.accentColor(for: w.0),
              isActive: isSelected
            )
            .scaleEffect(isSelected ? 1.015 : 1)
            .shadow(
              color: isSelected ? vm.accentColor(for: w.0).opacity(0.10) : .clear, radius: 6, x: 0,
              y: 3
            )
            .animation(.spring(response: 0.26, dampingFraction: 0.76), value: isSelected)
          }.buttonStyle(.plain)
        }
      }
    }

    var saveConfirmationView: some View {
      Label(vm.saveConfirmationText, systemImage: "checkmark.circle.fill")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(vm.moodieTint)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .moodieInsetSurface(cornerRadius: 14, tint: vm.moodieTint, isActive: true)
    }

    var saveButtonView: some View {
      let canSubmit = vm.canSubmitEntry

      return Button(action: vm.saveEntry) {
        Text(vm.canSaveToday ? "저장하기" : "오늘은 충분히 기록했어요")
          .fontWeight(.semibold)
          .frame(maxWidth: .infinity)
          .padding()
          .contentShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
        .background(
          canSubmit
            ? vm.accentColor(for: vm.selectedWeather) : Color.secondary.opacity(0.22)
        )
        .foregroundColor(canSubmit ? .white : .secondary)
        .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
      }
      .buttonStyle(.plain)
      .disabled(!canSubmit)
    }

    func entryRow(_ entry: MoodEntry, isHighlighted: Bool = false, showsDate: Bool = false) -> some View {
      HStack(spacing: 12) {
        Text(entry.emoji).font(.title2).frame(width: 44, height: 44)
          .moodieInsetSurface(
            cornerRadius: 22,
            tint: vm.accentColor(for: entry.weather),
            isActive: isHighlighted
          )
        VStack(alignment: .leading, spacing: 5) {
          Text(showsDate ? vm.formattedFullDate(entry.date) : vm.timeText(entry.date))
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
          Text(entry.note).font(.subheadline).foregroundStyle(.primary).lineLimit(2)
        }
        Spacer()
      }
      .padding(14)
      .moodieInsetSurface(
        cornerRadius: vm.cardCornerRadius,
        tint: vm.accentColor(for: entry.weather),
        isActive: isHighlighted
      )
      .scaleEffect(isHighlighted ? 1.01 : 1)
      .animation(.spring(response: 0.26, dampingFraction: 0.82), value: isHighlighted)
    }
}
