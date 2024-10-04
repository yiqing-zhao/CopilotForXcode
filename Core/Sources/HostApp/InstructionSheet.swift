import Foundation
import SwiftUI

struct InstructionSheet: View {
    let closeAction: () -> ()
    
    var body: some View {
        VStack(alignment: .center) {
            Image("copilotIcon")
                .resizable()
                .frame(width: 64, height: 64, alignment: .center)
                .padding(.top, 36)
                .padding(.bottom, 16)
            Text("Extension Permissions")
                .fontWeight(.heavy)
                .font(.system(size: 16))
            Text("To enable permissions in settings:")
                .font(.system(size: 14))
                .padding(.top, 4)

            VStack(alignment: .center) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue)
                            .frame(width: 13, height: 13)
                        
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 8, weight: .bold))
                    }

                    Text("Xcode Source Editor")
                        .font(.system(size: 12))

                    Image(systemName: "arrowshape.left.fill")
                        .resizable()
                        .foregroundColor(Color.red)
                        .frame(width: 40, height: 10)
                }
                .frame(height: 25)
                .padding(.horizontal, 12)
                
                HStack {
                    Image("copilotIcon")
                        .resizable()
                        .frame(width: 15, height: 15, alignment: .center)
                    Text("GitHub Copilot for Xcode")
                        .font(.system(size: 12))
                }
                .frame(height: 25)
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(5)
            .padding(.vertical, 10)

            VStack(spacing: 0) {
                Text("To view Copilot preferences in XCode, path:")
                    .font(.system(size: 12))
                    .padding(.top, 16)
                Text("Xcode Source Editor > GitHub Copilot")
                    .bold()
                    .font(.system(size: 12))
            }
            .padding(.horizontal)
            
            Button(action: closeAction, label:{
                Text("Close")
                    .foregroundColor(.white)
                    .frame(height: 28)
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(.borderedProminent)
            .cornerRadius(5)
            .padding(16)
            .padding(.bottom, 16)
        }
        .frame(width: 300, height: 376)
    }
}
