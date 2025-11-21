import SwiftUI

struct SetupWizardView: View {
    @ObservedObject var viewModel: SetupViewModel
    var onFinished: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                header
                Divider()
                content
                Divider()
                footer
            }
            .padding(24)
            .frame(minWidth: 700, minHeight: 500)
            .background(.background)
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding()
        }
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Initial Setup")
                .font(.title)
                .fontWeight(.bold)
            Text("SubDubAI needs to verify that required components are installed.")
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.step {
        case .welcome:
            welcomeContent
        case .checking:
            checkingContent
        case .summary:
            summaryContent
        }
    }

    @ViewBuilder
    private var footer: some View {
        HStack {
            if viewModel.step == .summary {
                Button("Retry") {
                    viewModel.retry()
                }
                .disabled(viewModel.isChecking)
            }

            Spacer()

            switch viewModel.step {
            case .welcome:
                Button("Continue") {
                    viewModel.startChecks()
                }
            case .checking:
                Button("Cancel") {
                    // Do nothing, user should wait for checks to complete
                }
                .disabled(true)
            case .summary:
                Button("Finish") {
                    onFinished()
                }
                .disabled(!viewModel.allDependenciesSatisfied)
            }
        }
    }

    private var welcomeContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Before you start, SubDubAI will check a few components:")
            VStack(alignment: .leading, spacing: 12) {
                ForEach(DependencyKind.allCases) { kind in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 8))
                            .padding(.top, 5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kind.title)
                                .fontWeight(.semibold)
                            Text(kind.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            Spacer()
        }
    }

    private var checkingContent: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Checking dependencies...")
                }

                if !viewModel.statuses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.statuses) { status in
                            dependencyRow(status)
                        }
                    }
                }

                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Whisper log")
                    .font(.headline)
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(viewModel.whisperProgressMessages.enumerated()), id: \.offset) { _, message in
                            Text(message)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .frame(width: 280)
        }
    }

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.allDependenciesSatisfied {
                Text("All required components are ready.")
                    .font(.headline)
            } else {
                Text("Some components need your attention.")
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.statuses) { status in
                    dependencyRow(status)
                }
            }

            Spacer()
        }
    }

    private func dependencyRow(_ status: DependencyStatus) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: status.isSatisfied ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundColor(status.isSatisfied ? .green : .red)
            VStack(alignment: .leading, spacing: 2) {
                Text(status.kind.title)
                    .fontWeight(.semibold)
                Text(status.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
