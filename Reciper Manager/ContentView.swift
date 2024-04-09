import SwiftUI

struct Recipe: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String
    var ingredients: [String]
    var instructions: String
    var imageData: Data? // Store image data as Data
    var category: String
    var isFavorite: Bool = false
    var image: Image? // Optional image

    enum CodingKeys: String, CodingKey {
        case id, name, ingredients, instructions, category, isFavorite
        case imageData // Define a custom key for imageData
    }

    init(name: String, ingredients: [String], instructions: String, image: Image?, category: String) {
        self.name = name
        self.ingredients = ingredients
        self.instructions = instructions
        self.image = image
        self.category = category
        self.imageData = nil // Initialize imageData as nil initially
    }
    
    // Method to set image data from UIImage
    mutating func setImageData(from image: UIImage) {
        self.imageData = image.jpegData(compressionQuality: 0.5)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        ingredients = try container.decode([String].self, forKey: .ingredients)
        instructions = try container.decode(String.self, forKey: .instructions)
        category = try container.decode(String.self, forKey: .category)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        
        // Decode imageData as Data
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        
        // Convert imageData to Image if available
        if let imageData = imageData, let uiImage = UIImage(data: imageData) {
            image = Image(uiImage: uiImage)
        } else {
            image = nil
        }
    }
}

class RecipeManager {
    static let shared = RecipeManager()
    private let userDefaults = UserDefaults.standard
    private let key = "SavedRecipes"
    
    func saveRecipes(recipes: [Recipe]) {
        do {
            let data = try JSONEncoder().encode(recipes)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Error saving recipes: \(error.localizedDescription)")
        }
    }
    
    func loadRecipes() -> [Recipe] {
        guard let data = userDefaults.data(forKey: key) else { return [] }
        do {
            let recipes = try JSONDecoder().decode([Recipe].self, from: data)
            return recipes
        } catch {
            print("Error loading recipes: \(error.localizedDescription)")
            return []
        }
    }
}

struct ContentView: View {
    @State private var recipes = RecipeManager.shared.loadRecipes()
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
        var sortedCategories = Array(allCategories).sorted() // Sort categories alphabetically
        if let index = sortedCategories.firstIndex(of: "Other") {
            let otherCategory = sortedCategories.remove(at: index)
            sortedCategories.append(otherCategory) // Move "Other" to the end
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
                            // Toggle favorite status
                            if let index = self.recipes.firstIndex(where: { $0.id == recipe.id }) {
                                self.recipes[index].isFavorite.toggle()
                                self.saveRecipes() // Save recipes after modification
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
        saveRecipes() // Save recipes after deletion
    }
    
    // Add a saveRecipes() method to save recipes whenever they are modified
    func saveRecipes() {
        RecipeManager.shared.saveRecipes(recipes: recipes)
    }
}

struct RecipeRow: View {
    var recipe: Recipe
    var toggleFavorite: () -> Void
    
    @State private var downloadedImage: UIImage?
    @State private var imageData: Data?
    @State private var isLoading = false
    
    var body: some View {
        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
            HStack {
                if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: 50, height: 50)
                } else {
                    if let downloadedImage = downloadedImage {
                        Image(uiImage: downloadedImage)
                            .resizable()
                            .frame(width: 50, height: 50)
                    } else {
                        Image(systemName: "photo")
                            .frame(width: 50, height: 50)
                    }
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
            .onAppear {
                // Implement image loading logic here if needed
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecipeDetailView: View {
    var recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading) {
            if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
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
    @State private var newRecipeImageData: Data?
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
                    
                    if let imageData = newRecipeImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
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
                        ImagePicker(imageData: $newRecipeImageData)
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
                        var newRecipe = Recipe(name: newRecipeName, ingredients: ingredientsArray, instructions: newRecipeInstructions, image: nil, category: selectedCategory)
                        
                        if let imageData = newRecipeImageData {
                            newRecipe.imageData = imageData
                        }
                        
                        recipes.append(newRecipe)
                        isPresented = false
                        saveRecipes() // Save recipes after adding a new recipe
                    }
                    .disabled(newRecipeName.isEmpty || newRecipeIngredients.isEmpty || newRecipeInstructions.isEmpty) // Check if any field is empty
                }
            }
            .navigationTitle("Add Recipe")
        }
    }
    
    // Add a saveRecipes() method to save recipes whenever they are modified
    func saveRecipes() {
        RecipeManager.shared.saveRecipes(recipes: recipes)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.presentationMode) var presentationMode
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.imageData = uiImage.jpegData(compressionQuality: 0.5)
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
