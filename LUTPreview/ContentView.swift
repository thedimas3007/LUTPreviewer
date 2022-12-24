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
    @State var files: Array<String> = []
    @State var photoURL = URL(string: "")
    @State var selection = Set<String>()
    var body: some View {
        NavigationView {
            List(files, id:\.self, selection: $selection) { file in
                NavigationLink(destination: VStack {
                    Label(selection.first ?? "<none>", systemImage: "ant")
                    if (photoURL != nil) {
                        HStack {
                            let fileURL = URL(string: file)!
                            let cgImageSource = CGImageSourceCreateWithURL(photoURL! as CFURL, nil)!
                            let origImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil)!
                            let img = applyLUT(imageURL: photoURL!, lutURL: fileURL)
                            let cgImage = convertCIImageToCGImage(img)!
                            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                            GroupBox {
                                VStack {
                                    Label("Original", systemImage: "photo")
                                    Image(decorative: origImage, scale: 1.0)
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                            GroupBox {
                                VStack {
                                    Label("LUTed", systemImage: "wand.and.stars.inverse")
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                        }.padding(10)
                    } else {
                        let fileURL = URL(string: file)!
                        let lut = LUT(from: fileURL)!
                        List {
                            Section("LUT info") {
                                ListRows(title: "Filename", value: fileURL.lastPathComponent, icon: "doc")
                                ListRows(title: "Title", value: lut.title, icon: "textformat")
                                ListRows(title: "Description", value: lut.descriptionText, icon: "text.alignleft")
                                ListRows(title: "Size", value: "\(lut.size)", icon: "character.textbox")
                                ListRows(title: "Metadata", value: "\(lut.metadata)", icon: "info.circle")
                            }
                        }
                    }
                }.listStyle(.inset)) {
                    Label(URL(string: file)!.lastPathComponent, systemImage: "shippingbox")
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
                            if (!files.contains(url.absoluteString)) {
                                files.append(url.absoluteString)
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
                    files = files.filter {$0 != selection.first}
                    selection = [""]
                    photoURL = URL(string: "")
                }, label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                })
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(action: {
                    files = []
                    selection = [""]
                    photoURL = URL(string: "")
                }, label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
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

struct ListRows: View {
    let title: String
    let value: String
    var icon = ""
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
