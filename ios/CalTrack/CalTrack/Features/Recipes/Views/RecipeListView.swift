import SwiftUI

struct RecipeListView: View {
    let recipes: [RecipeResponse]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRecipe: RecipeResponse?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("\(recipes.count) tarif önerisi")
                        .font(.ctSubheadline)
                        .foregroundColor(.secondary)

                    ForEach(recipes) { recipe in
                        RecipeCard(recipe: recipe)
                            .onTapGesture { selectedRecipe = recipe }
                    }
                }
                .padding()
            }
            .navigationTitle("Tarifler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }
}

struct RecipeCard: View {
    let recipe: RecipeResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title)
                        .font(.ctHeadline)
                    Text(recipe.description)
                        .font(.ctCaption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                RecipeInfoChip(icon: "flame.fill", text: "\(Int(recipe.calories)) kcal", color: .ctCalories)
                RecipeInfoChip(icon: "clock.fill", text: "\(recipe.prepTimeMin + recipe.cookTimeMin) dk", color: .secondary)
                RecipeInfoChip(icon: "person.fill", text: "\(recipe.servings) kişi", color: .secondary)
            }

            HStack(spacing: 12) {
                MacroBadge(label: "P", value: Int(recipe.proteinG), color: .ctProtein)
                MacroBadge(label: "K", value: Int(recipe.carbsG), color: .ctCarbs)
                MacroBadge(label: "Y", value: Int(recipe.fatG), color: .ctFat)
                Spacer()
            }

            // Tags
            if !recipe.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(recipe.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.ctSecondaryBg)
        .cornerRadius(16)
    }
}

struct RecipeInfoChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(text)
                .font(.ctCaption)
                .foregroundColor(.secondary)
        }
    }
}

struct MacroBadge: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
            Text("\(value)g")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

struct RecipeDetailView: View {
    let recipe: RecipeResponse
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.title)
                            .font(.ctTitle)
                        Text(recipe.description)
                            .font(.ctSubheadline)
                            .foregroundColor(.secondary)
                    }

                    // Nutrition summary
                    HStack(spacing: 12) {
                        NutritionBadge(label: "Kalori", value: "\(Int(recipe.calories))", unit: "kcal", color: .ctCalories)
                        NutritionBadge(label: "Protein", value: "\(Int(recipe.proteinG))", unit: "g", color: .ctProtein)
                        NutritionBadge(label: "Karb", value: "\(Int(recipe.carbsG))", unit: "g", color: .ctCarbs)
                        NutritionBadge(label: "Yağ", value: "\(Int(recipe.fatG))", unit: "g", color: .ctFat)
                    }

                    // Time & servings
                    HStack(spacing: 20) {
                        Label("\(recipe.prepTimeMin) dk hazırlık", systemImage: "clock")
                        Label("\(recipe.cookTimeMin) dk pişirme", systemImage: "flame")
                        Label("\(recipe.servings) kişilik", systemImage: "person.2")
                    }
                    .font(.ctCaption)
                    .foregroundColor(.secondary)

                    Divider()

                    // Ingredients
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Malzemeler")
                            .font(.ctTitle2)

                        ForEach(recipe.ingredients, id: \.name) { ingredient in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.accentColor)
                                Text("\(ingredient.name)")
                                    .font(.ctBody)
                                Spacer()
                                Text("\(String(format: "%.0f", ingredient.amount)) \(ingredient.unit)")
                                    .font(.ctSubheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Yapılışı")
                            .font(.ctTitle2)

                        ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.ctHeadline)
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.accentColor)
                                    .cornerRadius(14)

                                Text(instruction)
                                    .font(.ctBody)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Save recipe button
                    Button(action: saveRecipe) {
                        HStack {
                            Image(systemName: "bookmark.fill")
                            Text("Tarifi Kaydet")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .fontWeight(.semibold)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private func saveRecipe() {
        let saved = SavedRecipe(from: recipe)
        modelContext.insert(saved)
        dismiss()
    }
}

