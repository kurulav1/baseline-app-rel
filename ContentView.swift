//
//  ContentView.swift
//  simpl3
//
//  Created by Väinö Kurula on 7.5.2023.
//


import SwiftUI

struct ContentView: View {
    @StateObject var usersViewModel = UsersViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    var body: some View {
        if appViewModel.isUserAuthenticated {
            TabView {
                UsersView()
                    .environmentObject(usersViewModel)
                    .environmentObject(appViewModel)
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("Users")
                    }
                    .onAppear {
                    }
                
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .onAppear {
                    }
                
                PlayListView()
                    .tabItem{
                        Image(systemName: "tennisball.fill")
                        Text("Play Listings")
                    }
                    .onAppear {
                    }
                
                ScheduledMatchesView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Scheduled Matches")
                    }
                    .onAppear {
                    }
                
                MatchRequestListView()
                    .tabItem {
                        Image(systemName: "clock")
                        Text("Requests")
                    }
                    .onAppear {
                    }
            }
        } else {
            LoginView(didCompleteLoginProcess: {
                //self.um.isCurrentlyLoggedOut = false
                //self.um.fetchAllUsers() // Fetch users after login
            })
        }
    }
}

