//
//  SharedComponents.swift
//  Furg
//
//  Reusable UI components: Loading skeletons, error states, empty states, and animations
//

import SwiftUI

// MARK: - Loading Skeleton

struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.05),
                Color.white.opacity(0.15),
                Color.white.opacity(0.05)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
        )
        .offset(x: isAnimating ? 200 : -200)
        .animation(
            .linear(duration: 1.5)
            .repeatForever(autoreverses: false),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

struct SkeletonModifier: ViewModifier {
    let isLoading: Bool
    var cornerRadius: CGFloat = 8

    func body(content: Content) -> some View {
        if isLoading {
            content
                .hidden()
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(0.1))
                        .overlay(SkeletonView())
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                )
        } else {
            content
        }
    }
}

extension View {
    func skeleton(isLoading: Bool, cornerRadius: CGFloat = 8) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading, cornerRadius: cornerRadius))
    }
}

// MARK: - Loading Skeleton Cards

struct SkeletonCard: View {
    var height: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonLine(width: 80)
            SkeletonLine(width: 150, height: 24)
            SkeletonLine(width: 100)
        }
        .padding(20)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct SkeletonLine: View {
    var width: CGFloat = 100
    var height: CGFloat = 14

    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(Color.white.opacity(0.1))
            .frame(width: width, height: height)
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.15),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: isAnimating ? geo.size.width : -geo.size.width * 0.5)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: height / 2))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

struct SkeletonTransactionRow: View {
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(SkeletonView().clipShape(Circle()))

            VStack(alignment: .leading, spacing: 6) {
                SkeletonLine(width: 120)
                SkeletonLine(width: 80, height: 10)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                SkeletonLine(width: 60)
                SkeletonLine(width: 40, height: 10)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct SkeletonAccountRow: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(SkeletonView().clipShape(RoundedRectangle(cornerRadius: 12)))

            VStack(alignment: .leading, spacing: 6) {
                SkeletonLine(width: 140)
                SkeletonLine(width: 80, height: 10)
            }

            Spacer()

            SkeletonLine(width: 70)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let title: String
    let message: String
    let icon: String
    var retryAction: (() -> Void)?

    init(
        title: String = "Something went wrong",
        message: String = "We couldn't load your data. Please try again.",
        icon: String = "exclamationmark.triangle.fill",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.furgDanger.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.furgDanger)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.furgCharcoal)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.furgMint.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.furgMint)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.furgCharcoal)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Network Error View

struct NetworkErrorView: View {
    var retryAction: () -> Void

    var body: some View {
        ErrorStateView(
            title: "No Connection",
            message: "Please check your internet connection and try again.",
            icon: "wifi.slash",
            retryAction: retryAction
        )
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .furgMint))
                    .scaleEffect(1.5)

                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.furgCharcoal)
            )
        }
    }
}

// MARK: - Success Overlay

struct SuccessOverlay: View {
    let message: String
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.furgSuccess.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.furgSuccess)
                }
                .scaleEffect(scale)

                Text(message)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.furgCharcoal)
            )
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1
                opacity = 1
            }
        }
    }
}

// MARK: - Pull to Refresh Indicator

struct RefreshIndicator: View {
    @Binding var isRefreshing: Bool

    var body: some View {
        HStack(spacing: 12) {
            if isRefreshing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .furgMint))
            }

            Text(isRefreshing ? "Updating..." : "Pull to refresh")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Animated View Transitions

struct SlideInModifier: ViewModifier {
    let isPresented: Bool
    let edge: Edge

    func body(content: Content) -> some View {
        content
            .offset(
                x: edge == .leading ? (isPresented ? 0 : -UIScreen.main.bounds.width) :
                   edge == .trailing ? (isPresented ? 0 : UIScreen.main.bounds.width) : 0,
                y: edge == .top ? (isPresented ? 0 : -UIScreen.main.bounds.height) :
                   edge == .bottom ? (isPresented ? 0 : UIScreen.main.bounds.height) : 0
            )
            .opacity(isPresented ? 1 : 0)
    }
}

extension View {
    func slideIn(isPresented: Bool, edge: Edge = .bottom) -> some View {
        modifier(SlideInModifier(isPresented: isPresented, edge: edge))
    }
}

// MARK: - Bounce Animation

struct BounceModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func bounceAnimation() -> some View {
        modifier(BounceModifier())
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.2),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: phase * geo.size.width * 2 - geo.size.width)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Pulsing Dot

struct PulsingDot: View {
    let color: Color
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .scaleEffect(isAnimating ? 1.3 : 1.0)
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Staggered Animation

struct StaggeredAnimation<Content: View>: View {
    let index: Int
    let content: Content

    @State private var isVisible = false

    init(index: Int, @ViewBuilder content: () -> Content) {
        self.index = index
        self.content = content()
    }

    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Toast Message

struct ToastMessage: View {
    let message: String
    let type: ToastType
    @Binding var isPresented: Bool

    enum ToastType {
        case success, error, warning, info

        var color: Color {
            switch self {
            case .success: return .furgSuccess
            case .error: return .furgDanger
            case .warning: return .furgWarning
            case .info: return .furgInfo
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            Button {
                withAnimation {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.furgSlate)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.furgCharcoal.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                // Skeleton examples
                Text("Loading Skeletons")
                    .font(.headline)
                    .foregroundColor(.white)

                SkeletonCard()
                SkeletonTransactionRow()
                SkeletonAccountRow()

                // Error state
                Text("Error State")
                    .font(.headline)
                    .foregroundColor(.white)

                ErrorStateView(retryAction: {})

                // Empty state
                Text("Empty State")
                    .font(.headline)
                    .foregroundColor(.white)

                EmptyStateView(
                    title: "No Transactions",
                    message: "Your transactions will appear here once you connect your bank.",
                    icon: "tray",
                    actionTitle: "Connect Bank",
                    action: {}
                )
            }
            .padding()
        }
    }
}
