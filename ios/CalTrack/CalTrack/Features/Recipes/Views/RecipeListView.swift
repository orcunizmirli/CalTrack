import SwiftUI

struct RecipeListView: View {
    let recipes: [RecipeResponse]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRecipe: RecipeResponse?

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer {
                    VStack(spacing: 16) {
                        Text("\(recipes.count) tarif önerisi")
                            .font(.ctSubheadline)
                            .foregroundStyle(.ctTextSecondary)

                        ForEach(recipes) { recipe in
                            RecipeCard(recipe: recipe)
                                .onTapGesture { selectedRecipe = recipe }
                        }
                    }
                    .padding()
                }
            }
            .background(Color.ctBackground)
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
                        .foregroundStyle(.ctTextSecondary)
                        .lineLimit(2)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                RecipeInfoChip(icon: "flame.fill", text: "\(Int(recipe.calories)) kcal", color: .ctAccent)
                RecipeInfoChip(icon: "clock.fill", text: "\(recipe.prepTimeMin + recipe.cookTimeMin) dk", color: .ctTextSecondary)
                RecipeInfoChip(icon: "person.fill", text: "\(recipe.servings) kişi", color: .ctTextSecondary)
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
                            .background(Color.ctAccent.opacity(0.1))
                            .foregroundStyle(.ctAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
        .glassCard()
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
                .foregroundStyle(color)
            Text(text)
                .font(.ctCaption)
                .foregroundStyle(.ctTextSecondary)
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
                .foregroundStyle(color)
            Text("\(value)g")
                .font(.system(size: 11))
                .foregroundStyle(.ctTextSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

struct RecipeDetailView: View {
    let recipe: RecipeResponse
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.title)
                            .font(.ctTitle)
                        Text(recipe.description)
                            .font(.ctSubheadline)
                            .foregroundStyle(.ctTextSecondary)
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
                    .foregroundStyle(.ctTextSecondary)

                    Divider()

                    // Ingredients
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Malzemeler")
                            .font(.ctTitle2)

                        ForEach(recipe.ingredients, id: \.name) { ingredient in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.ctAccent)
                                Text("\(ingredient.name)")
                                    .font(.ctBody)
                                Spacer()
                                Text("\(String(format: "%.0f", ingredient.amount)) \(ingredient.unit)")
                                    .font(.ctSubheadline)
                                    .foregroundStyle(.ctTextSecondary)
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
                                    .foregroundStyle(.black)
                                    .frame(width: 28, height: 28)
                                    .background(Color.ctAccent)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

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
                        .background(Color.ctAccent)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .fontWeight(.semibold)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(Color.ctBackground)
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
