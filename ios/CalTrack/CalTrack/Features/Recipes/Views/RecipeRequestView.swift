import SwiftUI

struct RecipeRequestView: View {
    @StateObject private var viewModel = RecipeViewModel()
    @State private var showResults = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)

                        Text("AI Tarif Önerisi")
                            .font(.ctTitle)

                        Text("Hedeflerine uygun akıllı tarifler oluştur")
                            .font(.ctSubheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)

                    // Remaining nutrients info
                    VStack(spacing: 8) {
                        Text("Bugün Kalan")
                            .font(.ctHeadline)
                        HStack(spacing: 16) {
                            NutritionBadge(label: "Kalori", value: "\(viewModel.remainingCalories)", unit: "kcal", color: .ctCalories)
                            NutritionBadge(label: "Protein", value: "\(viewModel.remainingProtein)", unit: "g", color: .ctProtein)
                            NutritionBadge(label: "Karb", value: "\(viewModel.remainingCarbs)", unit: "g", color: .ctCarbs)
                            NutritionBadge(label: "Yağ", value: "\(viewModel.remainingFat)", unit: "g", color: .ctFat)
                        }
                    }
                    .padding()
                    .background(Color.ctSecondaryBg)
                    .cornerRadius(14)

                    // Meal type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Öğün Tipi")
                            .font(.ctHeadline)

                        HStack(spacing: 8) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                Button(action: { viewModel.mealType = type }) {
                                    Text(type.displayName)
                                        .font(.ctCaption)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(viewModel.mealType == type ? Color.accentColor : Color.ctSecondaryBg)
                                        .foregroundColor(viewModel.mealType == type ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }

                    // Target calories for this meal
                    VStack(spacing: 12) {
                        HStack {
                            Text("Hedef Kalori")
                                .font(.ctHeadline)
                            Spacer()
                            Text("\(viewModel.targetCalories) kcal")
                                .font(.ctMacroValue)
                                .foregroundColor(.accentColor)
                        }
                        Slider(value: Binding(
                            get: { Double(viewModel.targetCalories) },
                            set: { viewModel.targetCalories = Int($0) }
                        ), in: 100...2000, step: 50)
                        .tint(.accentColor)
                    }
                    .padding()
                    .background(Color.ctSecondaryBg)
                    .cornerRadius(14)

                    // Preferred ingredients
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tercih Ettiğin Malzemeler (opsiyonel)")
                            .font(.ctHeadline)

                        TextField("Ör: tavuk göğsü, pirinç, brokoli", text: $viewModel.preferredIngredients)
                            .textFieldStyle(.roundedBorder)

                        Text("Virgül ile ayırarak birden fazla malzeme girebilirsin")
                            .font(.ctCaption)
                            .foregroundColor(.secondary)
                    }

                    // Dietary restrictions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Diyet Kısıtlamaları")
                            .font(.ctHeadline)

                        let restrictions = ["Glutensiz", "Vegan", "Vejetaryen", "Laktozsuz", "Keto", "Düşük Karbonhidrat"]
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(restrictions, id: \.self) { restriction in
                                Button(action: {
                                    if viewModel.dietaryRestrictions.contains(restriction) {
                                        viewModel.dietaryRestrictions.removeAll { $0 == restriction }
                                    } else {
                                        viewModel.dietaryRestrictions.append(restriction)
                                    }
                                }) {
                                    Text(restriction)
                                        .font(.ctCaption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(viewModel.dietaryRestrictions.contains(restriction) ? Color.accentColor : Color.ctSecondaryBg)
                                        .foregroundColor(viewModel.dietaryRestrictions.contains(restriction) ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }

                    // Generate button
                    Button(action: {
                        Task {
                            await viewModel.generateRecipes()
                            if !viewModel.recipes.isEmpty { showResults = true }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                Text("Tarif Oluştur")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .fontWeight(.semibold)
                    }
                    .disabled(viewModel.isLoading)

                    if let error = viewModel.error {
                        Text(error)
                            .font(.ctFootnote)
                            .foregroundColor(.ctError)
                    }
                }
                .padding()
            }
            .navigationTitle("Tarif Önerisi")
            .sheet(isPresented: $showResults) {
                RecipeListView(recipes: viewModel.recipes)
            }
        }
    }
}
