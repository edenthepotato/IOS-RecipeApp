import SwiftUI

struct FavoriteRecipesView: View {
    @Binding var recipes: [Recipe]

    var favoriteRecipes: [Recipe] {
        return recipes.filter { $0.isFavorite }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(favoriteRecipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        RecipeRow(recipe: recipe, toggleFavorite: {})
                    }
                }
            }
            .navigationBarTitle("Favorite Recipes")
        }
    }
}
