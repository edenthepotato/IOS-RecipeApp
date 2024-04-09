import SwiftUI

struct Recipe: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var ingredients: [String]
    var instructions: String
    var image: Image?
    var category: String
    var isFavorite: Bool = false
}

struct ContentView: View {
    @State private var recipes = [
        Recipe(name: "Pasta", ingredients: ["Pasta", "Tomato sauce", "Cheese"], instructions: "Cook pasta, add sauce, sprinkle cheese", image: nil, category: "Italian"),
        Recipe(name: "Salad", ingredients: ["Lettuce", "Tomato", "Cucumber", "Dressing"], instructions: "Chop veggies, mix with dressing", image: nil, category: "Other"),
        Recipe(name: "Mac & Cheese", ingredients: ["Macaroni", "Cheese"], instructions: "Cook macaroni and put the cheese in", image: nil, category: "Other"),
    ]
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingFavoriteRecipes = false
    @State private var showingAddRecipeView = false
    
    var filteredRecipes: [Recipe] {
        var filtered = recipes
        
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.ingredients.joined(separator: " ").localizedCaseInsensitiveContains(searchText) }
        }
        
        return filtered
    }
    
    var categories: [String] {
        var allCategories = Set<String>()
        allCategories.insert("All")
        recipes.forEach { allCategories.insert($0.category) }
        var sortedCategories = Array(allCategories).sorted()
        if let index = sortedCategories.firstIndex(of: "Other") {
            let otherCategory = sortedCategories.remove(at: index)
            sortedCategories.append(otherCategory)
        }
        return sortedCategories
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(searchText: $searchText)
                
                Picker(selection: $selectedCategory, label: Text("Category")) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
                
                List {
                    ForEach(filteredRecipes) { recipe in
                        RecipeRow(recipe: recipe) {
                            if let index = self.recipes.firstIndex(where: { $0.id == recipe.id }) {
                                self.recipes[index].isFavorite.toggle()
                            }
                        }
                    }
                    .onDelete(perform: deleteRecipe)
                }
                .navigationBarTitle("Recipes")
                .navigationBarItems(trailing:
                    HStack {
                        Button(action: {
                            showingAddRecipeView = true
                        }) {
                            Image(systemName: "plus")
                        }
                        .sheet(isPresented: $showingAddRecipeView) {
                            AddRecipeView(recipes: self.$recipes, isPresented: $showingAddRecipeView)
                        }
                        
                        Button(action: {
                            showingFavoriteRecipes.toggle()
                        }) {
                            Image(systemName: "star.fill")
                        }
                        .sheet(isPresented: $showingFavoriteRecipes) {
                            FavoriteRecipesView(recipes: self.$recipes)
                        }
                    }
                )
            }
        }
    }
    
    func deleteRecipe(at offsets: IndexSet) {
        recipes.remove(atOffsets: offsets)
    }
}

    
struct RecipeRow: View {
    var recipe: Recipe
    var toggleFavorite: () -> Void
    var body: some View {
        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
            HStack {
                if let image = recipe.image {
                    image
                        .resizable()
                        .frame(width: 50, height: 50)
                }
                VStack(alignment: .leading) {
                    Text(recipe.name)
                    Text("Category: \(recipe.category)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                if recipe.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .onTapGesture {
                            self.toggleFavorite()
                        }
                } else {
                    Image(systemName: "star")
                        .foregroundColor(.gray)
                        .onTapGesture {
                            self.toggleFavorite()
                        }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(radius: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

    
    struct RecipeDetailView: View {
        var recipe: Recipe
        
        var body: some View {
            VStack(alignment: .leading) {
                if let image = recipe.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                }
                Text(recipe.name)
                    .font(.title)
                Text("Category: \(recipe.category)")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Ingredients:")
                    .font(.headline)
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    Text("- \(ingredient)")
                }
                Text("Instructions:")
                    .font(.headline)
                Text(recipe.instructions)
            }
            .padding()
            .navigationTitle(recipe.name)
        }
    }
    
    struct AddRecipeView: View {
        @Binding var recipes: [Recipe]
        @Binding var isPresented: Bool
        @State private var newRecipeName = ""
        @State private var newRecipeIngredients = ""
        @State private var newRecipeInstructions = ""
        @State private var newRecipeImage: Image? = nil
        @State private var selectedCategory = "Italian"
        @State private var showImagePicker = false
        
        let categories = ["Chinese", "Mexican", "Italian", "Indian", "French", "Other..."]
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Recipe Details")) {
                        TextField("Name", text: $newRecipeName)
                        TextField("Ingredients (comma-separated)", text: $newRecipeIngredients)
                        TextField("Instructions", text: $newRecipeInstructions)
                        
                        if let image = newRecipeImage {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                        }
                        
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Text("Add Image")
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(image: $newRecipeImage)
                        }
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Section {
                        Button("Add Recipe") {
                            let ingredientsArray = newRecipeIngredients.components(separatedBy: ",")
                            let newRecipe = Recipe(name: newRecipeName, ingredients: ingredientsArray, instructions: newRecipeInstructions, image: newRecipeImage, category: selectedCategory)
                            recipes.append(newRecipe)
                            isPresented = false
                        }
                        .disabled(newRecipeName.isEmpty || newRecipeIngredients.isEmpty || newRecipeInstructions.isEmpty)
                    }
                }
                .navigationTitle("Add Recipe")
            }
        }
    }
    
    struct ImagePicker: UIViewControllerRepresentable {
        @Binding var image: Image?
        @Environment(\.presentationMode) var presentationMode
        
        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            var parent: ImagePicker
            
            init(parent: ImagePicker) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let uiImage = info[.originalImage] as? UIImage {
                    parent.image = Image(uiImage: uiImage)
                }
                
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
        
        func makeCoordinator() -> Coordinator {
            return Coordinator(parent: self)
        }
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }

