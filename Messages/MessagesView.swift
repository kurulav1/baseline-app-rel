//
//  MessagesView.swift
//  simpl3
//
//  Created by Väinö Kurula on 11.5.2023.
//

// A view for displaying messages between two users.


import SwiftUI
import Firebase
import SDWebImageSwiftUI
import FirebaseFirestoreSwift

class LogViewModel: ObservableObject {
    
    @Published var messageText = ""
    @Published var errorMessage = ""
    @Published var messages = [Message]()
    
    var user : User?
    
    init(user: User?) {
        self.user = user
        fetchMessages()
    }
    
    var firestoreListener: ListenerRegistration?
    
    func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid  else { return }
        
        
        guard let toId = user?.uid else {return}
        
        
        firestoreListener?.remove()
        messages.removeAll()
        firestoreListener = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for messages: \(error)"
                    print(error)
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        do {
                            if let cm = try change.document.data(as: Message?.self) {
                                self.messages.append(cm)
                                print("Appending chatMessage in ChatLogView: \(Date())")
                            }
                        } catch {
                            print("Failed to decode message: \(error)")
                        }
                    }
                })
                
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
        
    }
    
    func handleSend() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = user?.uid else { return }
        
        let document = FirebaseManager.shared.firestore.collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .document()
        
        let msg = Message(id: nil, fromId: fromId, toId: toId, text: messageText, timestamp: Date())
        
        try? document.setData(from: msg) { error in
            if let error = error {
                self.errorMessage = "Failed to save sender message to firestore.."
                return
            }
            
            self.persistMessage()
            
            self.messageText = ""
            self.count += 1
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        
        try? recipientMessageDocument.setData(from: msg) { error in
            if let error = error {
                print(error)
                self.errorMessage = "Failed to save recipient message into Firestore: \(error) \(toId)"
                return
            }
            
            print("Recipient saved message as well")
        }
    }
    
    private func persistMessage() {
        guard let user = user else { return }
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = self.user?.uid else { return }
        
        let document = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .document(toId)
        
        let data = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.messageText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: user.profileImageUrl,
            FirebaseConstants.email: user.email
        ] as [String : Any]
            
        document.setData(data) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent message: \(error)"
                print("Failed to save recent message: \(error)")
                return
            }
        }

        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        let recipientRecentMessageDictionary = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.messageText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: currentUser.profileImageUrl,
            FirebaseConstants.email: currentUser.email
        ] as [String : Any]
        
        FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(toId)
            .collection(FirebaseConstants.messages)
            .document(currentUser.uid)
            .setData(recipientRecentMessageDictionary) { error in
                if let error = error {
                    print("Failed to save recipient recent message: \(error)")
                    return
                }
            }
    }
    
    @Published var count = 0
}


struct MessagesView: View {
    
    @ObservedObject var vm: LogViewModel
    @State private var isShowingNewView = false
    
    var body: some View {
        ZStack {
            messagesView
            Text(vm.errorMessage)
                .foregroundColor(.red)
        }
        .navigationBarTitle(vm.user?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing:
            Button(action: {
                self.isShowingNewView = true
            }) {
                Text("Button")
            }
        )
        .onDisappear {
            vm.firestoreListener?.remove()
        }
        .background(
            NavigationLink(destination: ForeignProfileView(vm: ForeignProfileViewModel(user: vm.user)), isActive: $isShowingNewView) {
                EmptyView()
            }
        )
    }
    
    private var messagesView: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack {
                        ForEach(vm.messages) { message in
                            MessageView(message: message)
                        }
                        .id("messages")
                        
                        HStack { Spacer() }
                            .id("scrollToBottom")
                    }
                    .onChange(of: vm.count) { _ in
                        withAnimation(.easeOut(duration: 0.5)) {
                            scrollViewProxy.scrollTo("scrollToBottom", anchor: .bottom)
                        }
                    }
                }
                .background(Color(.systemGroupedBackground))
                .safeAreaInset(edge: .bottom) {
                    chatBottomBar
                        .background(Color(.systemBackground).ignoresSafeArea())
                }
            }
        }
    }
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            
            ZStack {
                if vm.messageText.isEmpty {
                    DescriptionPlaceholder()
                }
                TextEditor(text: $vm.messageText)
                    .opacity(vm.messageText.isEmpty ? 0.5 : 1)
            }
            .frame(height: 40)
            
            Button(action: {
                vm.handleSend()
            }) {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct MessageView: View {
    
    let message: Message
    
    var body: some View {
        VStack {
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    Text(message.text)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            } else {
                HStack {
                    Text(message.text)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

private struct DescriptionPlaceholder: View {
    var body: some View {
        HStack {
            Text("Description")
                .foregroundColor(Color(.gray))
                .font(.system(size: 17))
                .padding(.leading, 5)
                .padding(.top, -4)
            Spacer()
        }
    }
}
