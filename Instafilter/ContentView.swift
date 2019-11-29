//
//  Copyright © 2019 Peter Barclay. All rights reserved.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct ContentView: View {
    @State private var image: Image?
    @State private var intensity = 0.5
    @State private var radius = 0.5
    @State private var scale = 0.5

    @State private var showingFilterSheet = false
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?

    @State private var showingError = false
    @State private var errorMessage: String = ""

    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    
    @State private var showingIntensitySlider = true
    @State private var showingRadiusSlider = false
    @State private var showingScaleSlider = false

    let context = CIContext()
    
    var body: some View {
        
        let intensity = Binding<Double>(
            get: {
                self.intensity
            },
            set: {
                self.intensity = $0
                self.applyProcessing()
            }
        )
        
        let radius = Binding<Double>(
            get: {
                self.radius
            },
            set: {
                self.radius = $0
                self.applyProcessing()
            }
        )
        
        let scale = Binding<Double>(
            get: {
                self.scale
            },
            set: {
                self.scale = $0
                self.applyProcessing()
            }
        )
        
        return NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color.secondary)
                    
                    if image != nil {
                        image?
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Tap to select a picture")
                            .foregroundColor(Color.white)
                            .font(.headline)
                    }
                }
                .onTapGesture {
                    self.showingImagePicker = true
                }
                
                VStack {
                    if self.showingIntensitySlider {
                        HStack {
                            Text("Intensity")
                            Slider(value: intensity)
                        }
                    }
                    
                    if self.showingRadiusSlider {
                        HStack {
                            Text("Radius")
                            Slider(value: radius)
                        }
                    }
                    
                    if self.showingScaleSlider {
                        HStack {
                            Text("Scale")
                            Slider(value: scale)
                        }
                    }
                }
                .padding()

                HStack {
                    Button(self.displayName(for: self.currentFilter)) {
                        self.showingFilterSheet = true
                    }
                    
                    Spacer()
                    
                    Button("Save") {
                        guard let processedImage = self.processedImage else {
                            self.errorMessage = "No Image selected"
                            self.showingError = true
                            return
                        }
                        
                        let imageSaver = ImageSaver()

                        imageSaver.successHandler = {
                            print("Success!")
                        }

                        imageSaver.errorHandler = {
                            self.errorMessage = $0.localizedDescription
                            self.showingError = true
                        }
                        
                        imageSaver.writeToPhotoAlbum(image: processedImage)
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationBarTitle("Instafilter")
            .sheet(isPresented: self.$showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            .actionSheet(isPresented: $showingFilterSheet) {
                ActionSheet(title: Text("Select a filter"), buttons: [
                    .default(Text(self.displayName(for: CIFilter.crystallize()))) {
                        self.setFilter(CIFilter.crystallize())
                    },
                    .default(Text(self.displayName(for: CIFilter.edges()))) {
                        self.setFilter(CIFilter.edges())
                    },
                    .default(Text(self.displayName(for: CIFilter.gaussianBlur()))) {
                        self.setFilter(CIFilter.gaussianBlur())
                    },
                    .default(Text(self.displayName(for: CIFilter.pixellate()))) {
                        self.setFilter(CIFilter.pixellate())
                    },
                    .default(Text(self.displayName(for: CIFilter.sepiaTone()))) {
                        self.setFilter(CIFilter.sepiaTone())
                    },
                    .default(Text(self.displayName(for: CIFilter.unsharpMask()))) {
                        self.setFilter(CIFilter.unsharpMask())
                    },
                    .default(Text(self.displayName(for: CIFilter.vignette()))) {
                        self.setFilter(CIFilter.vignette())
                    },
                    .cancel()
                ])
            }
            .alert(isPresented: $showingError) {
                Alert(title: Text(self.errorMessage))
            }
        }
    }
    
    private func displayName(for filter: CIFilter) -> String {
        var res : String! = nil
        if let disp = filter.attributes[kCIAttributeFilterDisplayName] as? String {
            res = disp
        }
        return res
    }
    
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        
        updateSliderss(for: filter)

        loadImage()
    }
    
    func updateSliderss(for filter: CIFilter) {
        let inputKeys = filter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) { self.showingIntensitySlider = true }
        if inputKeys.contains(kCIInputRadiusKey) { self.showingRadiusSlider = true  }
        if inputKeys.contains(kCIInputScaleKey) { self.showingScaleSlider = true  }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }

        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(intensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(radius * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(scale * 10, forKey: kCIInputScaleKey) }
        
        guard let outputImage = currentFilter.outputImage else {
            return
        }
        
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
