//
//  ContentView.swift
//  LUTPreview
//
//  Created by Dima on 23.12.2022.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreImage
import CoreGraphics
import CocoaLUT

struct ContentView: View {
    func applyLUT(imageURL: URL, lutURL: URL) -> CIImage {
        let image = CIImage(contentsOf: imageURL)
        let lut = LUT(from: lutURL)
        return lut!.processCIImage(image)
    }
    func convertCIImageToCGImage(_ inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
            return cgImage
        }
        return nil
    }
    @State var files: Array<URL> = []
    @State var listSelection = Set<String>()
    @State var photoURL = URL(string: "")
    var body: some View {
        NavigationView {
            List(files, id:\.self, selection: $listSelection) { fileURL in
                let file = fileURL.lastPathComponent
                NavigationLink(destination: List() {
                    if (photoURL != nil) {
//                        Label(photoURL!.lastPathComponent, systemImage: "photo")
                        HStack {
//                            AsyncImage(url: photoURL)
//                                .resizable()
//                                .aspectRatio(contentMode:)
                            let cgImageSource = CGImageSourceCreateWithURL(photoURL! as CFURL, nil)!
                            let origImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil)!
                            let img = applyLUT(imageURL: photoURL!, lutURL: fileURL)
                            let cgImage = convertCIImageToCGImage(img)!
                            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                            GroupBox {
                                HStack {
                                    VStack {
                                        Label("Original", systemImage: "photo")
                                        Image(decorative: origImage, scale: 1.0)
                                            .resizable()
                                            .scaledToFit()
                                    }
                                    VStack {
                                        Label("LUTed", systemImage: "wand.and.stars.inverse")
                                        Image(nsImage: nsImage)
                                            .resizable()
                                            .scaledToFit()
                                    }
                                }
                            }
                        }
                    } else {
                        Label(fileURL.lastPathComponent, systemImage: "cube.transparent")
                    }
                }.listStyle(.inset)) {
                    Label(file, systemImage: "shippingbox")
                }
            }.listStyle(SidebarListStyle())
        }.toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar, label: {
                    Image(systemName: "sidebar.left")
                })
            }
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    let panel = NSOpenPanel()
                    var arr = [UTType]()
                    arr.append(UTType(filenameExtension: "cube")!)
                    panel.allowsMultipleSelection = true
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = arr
                    if panel.runModal() == .OK {
                        panel.urls.forEach { url in
                            if (!files.contains(url)) {
                                files.append(url)
                            }
                        }
                    }
                }, label: {
                    Image(systemName: "doc")
                        .symbolVariant(SymbolVariants.square)
                })
            }
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [UTType.image]
                    if panel.runModal() == .OK {
                        photoURL = panel.url!
                    }
                }, label: {
                    Image(systemName: "photo")
                        .symbolVariant(SymbolVariants.square)
                })
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    print("Pre-removing...")
                    print(listSelection)
                    if (listSelection.count == 0) {
                        return
                    }
                    print("Removing...")
                    files = files.filter {$0.lastPathComponent != listSelection.first!}
                    listSelection.removeAll()
                }, label: {
                    Image(systemName: "xmark.circle")
                })
            }
        }
    }
    
    private func toggleSidebar() {
        #if os(iOS)
        #else
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
