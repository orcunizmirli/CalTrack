import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showAddFood = false
    @State private var selectedMealType: MealType = .breakfast

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer { VStack(spacing: 16) {
                    // Date Selector
                    DateSelectorView(selectedDate: $viewModel.selectedDate)
                        .onChange(of: viewModel.selectedDate) { _, _ in
                            Task { await viewModel.loadData(context: modelContext) }
                        }

                    // Calorie Ring
                    CalorieRingView(
                        consumed: viewModel.totalCalories,
                        goal: viewModel.calorieGoal,
                        burned: viewModel.activeCalories,
                        remaining: viewModel.caloriesRemaining
                    )
                    .padding(.horizontal)

                    // Macro Progress
                    MacroProgressView(
                        protein: viewModel.totalProtein,
                        proteinGoal: viewModel.proteinGoal,
                        carbs: viewModel.totalCarbs,
                        carbsGoal: viewModel.carbsGoal,
                        fat: viewModel.totalFat,
                        fatGoal: viewModel.fatGoal
                    )
                    .padding(.horizontal)

                    // Activity Summary
                    if viewModel.selectedDate.isToday {
                        HStack(spacing: 12) {
                            ActivityCard(icon: "figure.walk", label: "Adım", value: "\(viewModel.todaySteps)")
                            ActivityCard(icon: "flame.fill", label: "Yakılan", value: "\(Int(viewModel.activeCalories)) kcal")
                        }
                        .padding(.horizontal)
                    }

                    // Meals
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        MealSectionView(
                            mealType: mealType,
                            meals: viewModel.mealsForType(mealType),
                            totalCalories: viewModel.caloriesForMealType(mealType),
                            onAdd: {
                                selectedMealType = mealType
                                showAddFood = true
                            },
                            onDelete: { meal in
                                viewModel.deleteMeal(meal, context: modelContext)
                            }
                        )
                        .padding(.horizontal)
                    }

                    // Water Tracker
                    WaterTrackerView()
                        .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            } }
            .background(Color.ctBackground)
            .navigationTitle("CalTrack")
            .refreshable {
                await viewModel.loadData(context: modelContext)
            }
            .task {
                await viewModel.loadData(context: modelContext)
            }
            .sheet(isPresented: $showAddFood) {
                AddFoodView(mealType: selectedMealType)
            }
        }
    }
}

struct DateSelectorView: View {
    @Binding var selectedDate: Date

    var body: some View {
        HStack {
            Button(action: { changeDate(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.ctAccent)
            }

            Spacer()

            VStack(spacing: 2) {
                if selectedDate.isToday {
                    Text("Bugün")
                        .font(.ctHeadline)
                } else if selectedDate.isYesterday {
                    Text("Dün")
                        .font(.ctHeadline)
                } else {
                    Text(selectedDate.dayOfWeek.capitalized)
                        .font(.ctHeadline)
                }
                Text(selectedDate.fullDate)
                    .font(.ctCaption)
                    .foregroundStyle(.ctTextSecondary)
            }

            Spacer()

            Button(action: { changeDate(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(selectedDate.isToday ? .ctTextTertiary : .ctAccent)
            }
            .disabled(selectedDate.isToday)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            if newDate <= Date() {
                withAnimation { selectedDate = newDate.startOfDay }
            }
        }
    }
}

struct ActivityCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.ctAccent)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.ctCaption)
                    .foregroundStyle(.ctTextSecondary)
                Text(value)
                    .font(.ctHeadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}
