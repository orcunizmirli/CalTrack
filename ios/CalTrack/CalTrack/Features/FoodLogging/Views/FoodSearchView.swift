import SwiftUI
import SwiftData

struct FoodSearchView: View {
    var initialMealType: MealType = .lunch
    @StateObject private var viewModel = FoodSearchViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showBarcodeScan = false
    @State private var selectedFood: FoodItem?
    @State private var showAddCustomFood = false
    @State private var showFavorites = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.ctTextSecondary)
                        TextField("Yemek ara...", text: $viewModel.searchQuery)
                            .textFieldStyle(.plain)
                            .autocapitalization(.none)
                            .onChange(of: viewModel.searchQuery) { _, _ in
                                viewModel.search(context: modelContext)
                            }

                        if !viewModel.searchQuery.isEmpty {
                            Button(action: { viewModel.searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.ctTextSecondary)
                            }
                        }
                    }
                    .padding(12)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .glassEffect(.regular)

                    // Favorites button
                    Button(action: { showFavorites.toggle() }) {
                        Image(systemName: showFavorites ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(showFavorites ? .ctError : .ctAccent)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .glassEffect(.clear)
                    }

                    // Barcode button
                    Button(action: { showBarcodeScan = true }) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title2)
                            .foregroundStyle(.ctAccent)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .glassEffect(.clear)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Meal type chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Button(action: { viewModel.selectedMealType = type }) {
                                HStack(spacing: 4) {
                                    Image(systemName: type.icon)
                                        .font(.caption)
                                    Text(type.displayName)
                                        .font(.ctCaption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(viewModel.selectedMealType == type ? Color.ctAccent : Color.ctSurfaceElevated)
                                .foregroundStyle(viewModel.selectedMealType == type ? .black : .ctTextPrimary)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Content
                if viewModel.isSearching {
                    FoodSearchShimmerView()
                } else if showFavorites {
                    favoritesList
                } else if !viewModel.searchQuery.isEmpty {
                    searchResultsList
                } else {
                    recentAndFrequentList
                }
            }
            .background(Color.ctBackground)
            .navigationTitle("Yemek Ekle")
            .sheet(isPresented: $showBarcodeScan) {
                BarcodeScannerView(scannedCode: $viewModel.scannedBarcode)
            }
            .onChange(of: viewModel.scannedBarcode) { _, code in
                if let code = code {
                    Task { await viewModel.searchByBarcode(code) }
                }
            }
            .sheet(item: $selectedFood, onDismiss: {
                viewModel.loadFavorites(context: modelContext)
            }) { food in
                FoodDetailAddView(food: food, initialMealType: viewModel.selectedMealType)
            }
            .sheet(isPresented: $showAddCustomFood, onDismiss: {
                viewModel.loadRecentFromLocal(context: modelContext)
                viewModel.loadCustomFoods(context: modelContext)
            }) {
                CustomFoodEntryView(mealType: viewModel.selectedMealType)
            }
            .task {
                viewModel.selectedMealType = initialMealType
                viewModel.loadRecentFromLocal(context: modelContext)
                viewModel.loadCustomFoods(context: modelContext)
                viewModel.loadFavorites(context: modelContext)
            }
        }
    }

    private var searchResultsList: some View {
        List {
            if viewModel.searchResults.isEmpty {
                ContentUnavailableView(
                    "Sonuç bulunamadı",
                    systemImage: "magnifyingglass",
                    description: Text("'\(viewModel.searchQuery)' için sonuç yok")
                )
            } else {
                ForEach(viewModel.searchResults, id: \.id) { food in
                    FoodSearchRow(food: food)
                        .onTapGesture { selectedFood = food }
                }
            }
        }
        .listStyle(.plain)
    }

    private var favoritesList: some View {
        List {
            if viewModel.favoriteFoods.isEmpty {
                ContentUnavailableView(
                    "Henüz favori yok",
                    systemImage: "heart",
                    description: Text("Yemek detayında kalp ikonuna dokunarak favorilere ekleyin")
                )
            } else {
                Section("Favoriler") {
                    ForEach(viewModel.favoriteFoods, id: \.id) { food in
                        FoodSearchRow(food: food)
                            .onTapGesture { selectedFood = food }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.toggleFavorite(food, context: modelContext)
                                } label: {
                                    Label("Favoriden Çıkar", systemImage: "heart.slash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var recentAndFrequentList: some View {
        List {
            if !viewModel.recentMeals.isEmpty {
                Section("Son Eklenenler") {
                    ForEach(viewModel.recentMeals) { meal in
                        RecentMealRow(meal: meal)
                            .onTapGesture {
                                // Create a FoodItem from the recent meal to reuse
                                let food = FoodItem(
                                    id: UUID().uuidString,
                                    name: meal.foodName,
                                    servingSizeG: meal.quantityG,
                                    calories: meal.calories,
                                    proteinG: meal.proteinG,
                                    carbsG: meal.carbsG,
                                    fatG: meal.fatG
                                )
                                selectedFood = food
                            }
                    }
                }
            }

            if !viewModel.customFoods.isEmpty {
                Section("Özel Yemeklerim") {
                    ForEach(viewModel.customFoods, id: \.id) { food in
                        FoodSearchRow(food: food)
                            .onTapGesture { selectedFood = food }
                    }
                }
            }

            Section {
                Button(action: { showAddCustomFood = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.ctAccent)
                        Text("Özel Yemek Ekle")
                            .foregroundStyle(.ctAccent)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct FoodSearchRow: View {
    let food: FoodItem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.nameTr ?? food.name)
                    .font(.ctBody)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let brand = food.brand {
                        Text(brand)
                            .font(.ctCaption)
                            .foregroundStyle(.ctTextSecondary)
                    }
                    Text("\(food.servingLabel ?? "\(Int(food.servingSizeG))g")")
                        .font(.ctCaption)
                        .foregroundStyle(.ctTextSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(food.calories)) kcal")
                    .font(.ctSubheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text("P:\(Int(food.proteinG))")
                        .foregroundColor(.ctProtein)
                    Text("K:\(Int(food.carbsG))")
                        .foregroundColor(.ctCarbs)
                    Text("Y:\(Int(food.fatG))")
                        .foregroundColor(.ctFat)
                }
                .font(.system(size: 10))
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.ctTextSecondary)
        }
        .padding(.vertical, 4)
    }
}

struct FoodDetailAddView: View {
    let food: FoodItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var quantityG: Double
    @State private var servingCount: Double = 1.0
    @State private var selectedMealType: MealType
    @State private var isFavorited: Bool = false

    init(food: FoodItem, initialMealType: MealType) {
        self.food = food
        self._quantityG = State(initialValue: food.servingSizeG)
        self._selectedMealType = State(initialValue: initialMealType)
        self._isFavorited = State(initialValue: food.isFavorite)
    }

    private var nutrition: NutritionInfo {
        food.nutritionFor(grams: quantityG)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Food info
                    VStack(spacing: 4) {
                        Text(food.nameTr ?? food.name)
                            .font(.ctTitle)
                        if let brand = food.brand {
                            Text(brand)
                                .font(.ctSubheadline)
                                .foregroundStyle(.ctTextSecondary)
                        }
                    }
                    .padding(.top, 20)

                    // Meal type selector
                    HStack(spacing: 8) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Button(action: { selectedMealType = type }) {
                                HStack(spacing: 4) {
                                    Image(systemName: type.icon)
                                        .font(.caption2)
                                    Text(type.displayName)
                                        .font(.ctCaption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(selectedMealType == type ? Color.ctAccent : Color.ctSurfaceElevated)
                                .foregroundStyle(selectedMealType == type ? .black : .ctTextPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }

                    // Serving selector
                    VStack(spacing: 12) {
                        HStack {
                            Text("Porsiyon")
                                .font(.ctHeadline)
                            Spacer()
                            Text("\(Int(quantityG))g")
                                .font(.ctMacroValue)
                                .foregroundStyle(.ctAccent)
                        }

                        Slider(value: $quantityG, in: 10...1000, step: 10)
                            .tint(.ctAccent)

                        // Quick serving buttons
                        HStack(spacing: 8) {
                            ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { multiplier in
                                Button(action: {
                                    quantityG = food.servingSizeG * multiplier
                                }) {
                                    Text(multiplier == 1.0 ? "1 porsiyon" : "\(String(format: "%.1f", multiplier))×")
                                        .font(.ctCaption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.ctSurfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .foregroundStyle(.ctTextPrimary)
                            }
                        }
                    }
                    .glassCard()

                    // Nutrition info
                    VStack(spacing: 12) {
                        NutritionRow(label: "Kalori", value: "\(Int(nutrition.calories))", unit: "kcal", color: .ctCalories)
                        Divider()
                        NutritionRow(label: "Protein", value: String(format: "%.1f", nutrition.proteinG), unit: "g", color: .ctProtein)
                        Divider()
                        NutritionRow(label: "Karbonhidrat", value: String(format: "%.1f", nutrition.carbsG), unit: "g", color: .ctCarbs)
                        Divider()
                        NutritionRow(label: "Yağ", value: String(format: "%.1f", nutrition.fatG), unit: "g", color: .ctFat)
                        if nutrition.fiberG > 0 {
                            Divider()
                            NutritionRow(label: "Lif", value: String(format: "%.1f", nutrition.fiberG), unit: "g", color: .secondary)
                        }
                    }
                    .glassCard()

                    // Add button
                    Button(action: addMeal) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("\(selectedMealType.displayName)'ne Ekle")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.ctAccent)
                        .foregroundStyle(.black)
                        .cornerRadius(14)
                        .fontWeight(.semibold)
                    }
                }
                .padding()
            }
            .background(Color.ctBackground)
            .navigationTitle("Yemek Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        toggleFavorite()
                    }) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorited ? .ctError : .ctTextSecondary)
                    }
                }
            }
            .task {
                if let existing = findExistingFood() {
                    isFavorited = existing.isFavorite
                }
            }
        }
    }

    /// Find existing FoodItem in SwiftData by id, then by name as fallback
    private func findExistingFood() -> FoodItem? {
        guard let allFoods = try? modelContext.fetch(FetchDescriptor<FoodItem>()) else { return nil }
        if let match = allFoods.first(where: { $0.id == food.id }) { return match }
        let name = (food.nameTr ?? food.name).lowercased()
        return allFoods.first(where: { ($0.nameTr ?? $0.name).lowercased() == name })
    }

    private func toggleFavorite() {
        if let existing = findExistingFood() {
            existing.isFavorite.toggle()
            existing.lastUsedAt = Date()
            isFavorited = existing.isFavorite
        } else {
            food.isFavorite = true
            food.lastUsedAt = Date()
            food.useCount += 1
            modelContext.insert(food)
            isFavorited = true
        }
    }

    private func addMeal() {
        // Save FoodItem to SwiftData if not already there
        let existingFood = findExistingFood()
        if let existingFood {
            existingFood.lastUsedAt = Date()
            existingFood.useCount += 1
        } else {
            food.lastUsedAt = Date()
            food.useCount += 1
            modelContext.insert(food)
        }

        let entry = MealEntry(
            foodId: food.id,
            foodName: food.nameTr ?? food.name,
            mealType: selectedMealType,
            quantityG: quantityG,
            calories: nutrition.calories,
            proteinG: nutrition.proteinG,
            carbsG: nutrition.carbsG,
            fatG: nutrition.fatG
        )
        modelContext.insert(entry)
        dismiss()
    }
}

struct NutritionRow: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.ctBody)
            Spacer()
            Text(value)
                .font(.ctHeadline)
            Text(unit)
                .font(.ctCaption)
                .foregroundStyle(.ctTextSecondary)
        }
    }
}

struct RecentMealRow: View {
    let meal: RecentMealItem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.foodName)
                    .font(.ctBody)
                    .lineLimit(1)
                Text("\(Int(meal.quantityG))g")
                    .font(.ctCaption)
                    .foregroundStyle(.ctTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(meal.calories)) kcal")
                    .font(.ctSubheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text("P:\(Int(meal.proteinG))")
                        .foregroundColor(.ctProtein)
                    Text("K:\(Int(meal.carbsG))")
                        .foregroundColor(.ctCarbs)
                    Text("Y:\(Int(meal.fatG))")
                        .foregroundColor(.ctFat)
                }
                .font(.system(size: 10))
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.ctTextSecondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddFoodView: View {
    let mealType: MealType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            FoodSearchView(initialMealType: mealType)
                .navigationTitle("\(mealType.displayName) - Yemek Ekle")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Kapat") { dismiss() }
                    }
                }
        }
    }
}

extension FoodItem: Identifiable {}
