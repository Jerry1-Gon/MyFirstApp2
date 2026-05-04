//
//  ContentView.swift
//  Final project 2
//
//  Created by Jerry Gonzalez on 4/13/26.
//
import SwiftUI
import AVFoundation
import AVKit
import EventKit
import PassKit
import UIKit
internal import Combine


// MARK: - Models

struct Song: Identifiable, Decodable {
    let id: Int
    let trackName: String?
    let artistName: String?
    let previewUrl: String?
    let trackViewUrl: String?

    enum CodingKeys: String, CodingKey {
        case id = "trackId"
        case trackName
        case artistName
        case previewUrl
        case trackViewUrl
    }
    

    var title: String { trackName ?? "Unknown Title" }
    var artist: String { artistName ?? "Unknown Artist" }
    var streamURL: String { previewUrl ?? "" }
}

struct SearchResponse: Decodable {
    let results: [Song]
}

struct EventItem: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let location: String
    let startDate: Date
    let endDate: Date
    let reminderMinutes: Int
    let videoQuery: String
}

// MARK: - Demo Events


let demoEvents: [EventItem] = [
    EventItem(
        title: "Summer Live Session",
        artist: "Nova Lane",
        location: "Main Stage",
        startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 18, hour: 20, minute: 0))!,
        endDate: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 18, hour: 21, minute: 30))!,
        reminderMinutes: 60,
        videoQuery: "MC Flow"
    ),
    EventItem(
        title: "Midnight Echo Showcase",
        artist: "Midnight Echo",
        location: "Studio 2",
        startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 20, hour: 21, minute: 30))!,
        endDate: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 20, hour: 23, minute: 0))!,
        reminderMinutes: 30,
        videoQuery: "Midnight Echo"
    ),
    EventItem(
        title: "Acoustic Night",
        artist: "The Harbor",
        location: "Rooftop",
        startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 22, hour: 19, minute: 15))!,
        endDate: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 22, hour: 20, minute: 45))!,
        reminderMinutes: 45,
        videoQuery: "The Harbor"
    ),
    EventItem(
        title: "Rock Live Show",
        artist: "The Rebels",
        location: "Arena Stage",
        startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 1, hour: 20, minute: 0))!,
        endDate: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 1, hour: 22, minute: 0))!,
        reminderMinutes: 30,
        videoQuery: "The Rebels"
    ),
    EventItem(
        title: "Hip Hop Night",
        artist: "MC Flow",
        location: "Club Stage",
        startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 21, minute: 0))!,
        endDate: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 23, minute: 0))!,
        reminderMinutes: 45,
        videoQuery: "MC Flow"
    )
]

// MARK: - Calendar Helper

enum CalendarHelper {
    static func addToCalendar(_ event: EventItem, saveMessage: @escaping (String) -> Void) {
        let store = EKEventStore()

        func saveEvent() {
            let calendarEvent = EKEvent(eventStore: store)
            calendarEvent.title = event.title
            calendarEvent.startDate = event.startDate
            calendarEvent.endDate = event.endDate
            calendarEvent.notes = "Artist: \(event.artist)\nLocation: \(event.location)"
            calendarEvent.timeZone = .current

            guard let defaultCalendar = store.defaultCalendarForNewEvents else {
                saveMessage("No default calendar available.")
                return
            }

            calendarEvent.calendar = defaultCalendar
            calendarEvent.addAlarm(EKAlarm(relativeOffset: TimeInterval(-event.reminderMinutes * 60)))

            do {
                try store.save(calendarEvent, span: .thisEvent)
                saveMessage("Added to Calendar with a reminder.")
            } catch {
                saveMessage("Could not save event: \(error.localizedDescription)")
            }
        }

        if #available(iOS 17.0, *) {
            store.requestWriteOnlyAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    if let error {
                        saveMessage("Calendar error: \(error.localizedDescription)")
                        return
                    }
                    guard granted else {
                        saveMessage("Calendar access denied.")
                        return
                    }
                    saveEvent()
                }
            }
        } else {
            store.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    if let error {
                        saveMessage("Calendar error: \(error.localizedDescription)")
                        return
                    }
                    guard granted else {
                        saveMessage("Calendar access denied.")
                        return
                    }
                    saveEvent()
                }
            }
        }
    }
}



// MARK: - Main App
struct ContentView: View {
    var body: some View {
        TabView {
            
            MusicView()
                .tabItem {
                    Image(systemName: "music.note")
                    Text("Music")
                }
            

            LiveEventsView()
                .tabItem {
                    Image(systemName: "dot.radiowaves.left.and.right")
                    Text("Live")
                }

            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }

            ShopView()
                .tabItem {
                    Image(systemName: "cart")
                    Text("Shop")
                }
                .tint(.blue)
        }
    }
}

// MARK: - Music Tab

struct MusicView: View {
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var searchText = ""
    @State private var songs: [Song] = []
    @State private var isLoading = false
    @State private var statusText = "Search for a song."

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    Button("Search") {
                        Task { await searchSongs() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Play Local Song") {
                        playLocalSong()
                    }
                    .buttonStyle(.bordered)
                }

                Text(statusText)
                    .foregroundStyle(.secondary)

                if isLoading {
                    ProgressView()
                }

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(songs) { song in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(song.title)
                                    .font(.headline)

                                Text(song.artist)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                playPreview(song.streamURL)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Button(isPlaying ? "Pause" : "Play") {
                    togglePlay()
                }
                .buttonStyle(.bordered)
                .padding(.bottom)
            }
            .navigationTitle("Music")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @MainActor
    private func playLocalSong() {
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "mp3") else {
            statusText = "sample.mp3 was not found."
            return
        }

        player = AVPlayer(url: url)
        player?.play()
        isPlaying = true
        statusText = "Playing local song."
    }

    @MainActor
    private func playPreview(_ previewUrl: String?) {
        guard let previewUrl, let url = URL(string: previewUrl) else {
            statusText = "No preview available."
            return
        }

        player = AVPlayer(url: url)
        player?.play()
        isPlaying = true
        statusText = "Playing preview."
    }

    @MainActor
    private func searchSongs() async {
        isLoading = true
        defer { isLoading = false }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            statusText = "Type something first."
            return
        }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://itunes.apple.com/search?term=\(encodedQuery)&entity=song&limit=10"

        guard let url = URL(string: urlString) else {
            statusText = "Invalid search URL."
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(SearchResponse.self, from: data)
            songs = result.results
            statusText = songs.isEmpty ? "No songs found." : "Found \(songs.count) songs."
        } catch {
            statusText = "Search failed."
            print(error)
        }
    }

    private func togglePlay() {
        guard let player else { return }

        if isPlaying {
            player.pause()
            statusText = "Paused"
        } else {
            player.play()
            statusText = "Playing"
        }

        isPlaying.toggle()
    }
}

// MARK: - Live Tab

struct LiveEventsView: View {
    @State private var saveMessages: [UUID: String] = [:]

    var body: some View {
        NavigationStack {
            List(demoEvents) { event in
                VStack(alignment: .leading, spacing: 8) {
                    NavigationLink(destination: LiveEventPlayerView(event: event)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(event.title)
                                .font(.headline)

                            Text(event.artist)
                                .foregroundStyle(.secondary)

                            Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)

                            Text(event.location)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("🔴 Live Event")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .buttonStyle(.plain)

              
                    Button("Play") {
                        CalendarHelper.addToCalendar(event) { message in
                            saveMessages[event.id] = message
                        }
                    }
                    .buttonStyle(.borderedProminent)
                     
            

                    if let message = saveMessages[event.id], !message.isEmpty {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
             
                .padding(.vertical, 6)
            }
           
            .navigationTitle("Live")
            
        }
    }
}

struct LiveEventPlayerView: View {
    let event: EventItem
    @State private var video: Song?
    @State private var isLoading = true
    @State private var statusText = "Loading iTunes video..."

    var body: some View {
        VStack(spacing: 16) {
            Text("🔴 Live Now")
                .font(.headline)
                .foregroundStyle(.red)

            Text(event.title)
                .font(.title2.bold())

            Text("\(event.artist) • \(event.location)")
                .foregroundStyle(.secondary)

            if isLoading {
                ProgressView()
            } else if let video, let url = URL(string: video.streamURL), !video.streamURL.isEmpty {
                AVPlayerControllerView(url: url)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
            } else {
                Text(statusText)
                    .foregroundStyle(.secondary)
                    .padding()
            }

            Spacer()
        }
        .padding(.top, 20)
        .navigationTitle("Live Show")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadITunesVideo()
        }
    }

    @MainActor
    private func loadITunesVideo() async {
        isLoading = true
        defer { isLoading = false }

        let query = "\(event.videoQuery) music video"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://itunes.apple.com/search?term=\(encodedQuery)&entity=musicVideo&limit=1"

        guard let url = URL(string: urlString) else {
            statusText = "Invalid search URL."
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(SearchResponse.self, from: data)

            if let first = result.results.first, !first.streamURL.isEmpty {
                video = first
                statusText = "Playing iTunes video."
            } else {
                statusText = "No iTunes video found for this event."
            }
        } catch {
            statusText = "Failed to load iTunes video."
            print(error)
        }
    }
}

struct AVPlayerControllerView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        controller.showsPlaybackControls = true
        player.play()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player == nil {
            let player = AVPlayer(url: url)
            uiViewController.player = player
            player.play()
        }
    }
}

// MARK: - Calendar Tab

struct CalendarView: View {
    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()
    @State private var noteText = ""
    @State private var savedNotes: [Date: String] = [:]

    private let calendar = Calendar.current

    private struct CalendarCell: Identifiable {
        let id = UUID()
        let date: Date?
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monthHeader
                    weekdayHeader
                    monthGrid
                    editorSection
                    eventsForSelectedDay
                }
                .padding(.vertical)
            }
            .navigationTitle("Calendar")
            .onAppear {
                loadNoteForSelectedDate()
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(displayedMonth.formatted(.dateTime.year().month(.wide)))
                .font(.headline)

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
    }

    private var weekdayHeader: some View {
        let symbols = calendar.shortStandaloneWeekdaySymbols

        return HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var monthGrid: some View {
        let cells = monthCells()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(cells) { cell in
                if let date = cell.date {
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let hasNote = !(savedNotes[startOfDay(for: date)] ?? "").isEmpty
                    let dayEvents = events(on: date)
                    let eventColor = dayEvents.first.map { colorForEvent($0) } ?? .red

                    Button {
                        selectedDate = date
                        loadNoteForSelectedDate()
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)

                            if !dayEvents.isEmpty {
                                Text(dayEvents.count == 1 ? "Live" : "\(dayEvents.count) Live")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(eventColor.opacity(0.15))
                                    .foregroundStyle(eventColor)
                                    .clipShape(Capsule())
                            } else if hasNote {
                                Circle()
                                    .frame(width: 6, height: 6)
                                    .foregroundStyle(.blue)
                            } else {
                                Color.clear.frame(width: 6, height: 6)
                            }
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? Color.blue.opacity(0.2) : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(height: 58)
                }
            }
        }
        .padding(.horizontal)
    }

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedDate, format: .dateTime.year().month(.wide).day())
                .font(.headline)
                .padding(.horizontal)

            TextEditor(text: $noteText)
                .frame(height: 140)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

            HStack {
                Button("Save Note") {
                    let day = startOfDay(for: selectedDate)
                    savedNotes[day] = noteText
                }
                .buttonStyle(.borderedProminent)

                Button("Clear") {
                    noteText = ""
                    savedNotes[startOfDay(for: selectedDate)] = ""
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
    }

    private var eventsForSelectedDay: some View {
        let dayEvents = events(on: selectedDate)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Live events for this day")
                .font(.headline)
                .padding(.horizontal)

            if dayEvents.isEmpty {
                Text("No live events on this day.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 10) {
                    ForEach(dayEvents) { event in
                        let eventColor = colorForEvent(event)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Circle()
                                    .fill(eventColor)
                                    .frame(width: 10, height: 10)

                                Text(event.title)
                                    .font(.subheadline.weight(.semibold))

                                Spacer()
                            }

                            Text(event.artist)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(eventColor.opacity(0.18))
                                .foregroundStyle(eventColor)
                                .clipShape(Capsule())

                            Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(eventColor.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(eventColor.opacity(0.45), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
            selectedDate = newMonth
            loadNoteForSelectedDate()
        }
    }

    private func loadNoteForSelectedDate() {
        let day = startOfDay(for: selectedDate)
        noteText = savedNotes[day] ?? ""
    }

    private func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func monthCells() -> [CalendarCell] {
        guard let interval = calendar.dateInterval(of: .month, for: displayedMonth) else {
            return []
        }

        let start = interval.start
        let range = calendar.range(of: .day, in: .month, for: displayedMonth) ?? 1..<32
        let firstWeekday = calendar.component(.weekday, from: start)

        var cells: [CalendarCell] = Array(repeating: CalendarCell(date: nil), count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: start) {
                cells.append(CalendarCell(date: date))
            }
        }

        return cells
    }

    private func events(on date: Date) -> [EventItem] {
        demoEvents.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }

    private func colorForEvent(_ event: EventItem) -> Color {
        let key = "\(event.title)-\(event.artist)-\(event.location)"
        let value = abs(key.hashValue) % 5

        switch value {
        case 0: return .red
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        default: return .purple
        }
    }
}
// MARK: - Shop Tab

struct CheckoutSummaryItem: Identifiable {
    let id = UUID()
    let name: String
    let quantity: Int
    let total: Double
}

struct ShopItem: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
    let description: String
    let systemImage: String
}

@MainActor
final class ApplePayCheckoutManager: NSObject, ObservableObject, PKPaymentAuthorizationControllerDelegate {
    @Published var statusMessage: String = ""
    @Published var showConfirmation = false
    @Published var confirmationItems: [CheckoutSummaryItem] = []
    @Published var confirmationTotal: Double = 0
    @Published var orderNumber: String = ""
    @Published var deliveryMessage: String = ""
    @Published var trackingNumber: String = ""

    private var paymentController: PKPaymentAuthorizationController?

    // Replace with your real Apple Pay merchant ID from Apple Developer
    private let merchantIdentifier = "merchant.com.yourcompany.yourapp"
    private let supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex, .discover]

    func startCheckout(items: [ShopItem], quantities: [UUID: Int]) {
        let selectedItems = items.compactMap { item -> CheckoutSummaryItem? in
            let qty = max(0, quantities[item.id, default: 0])
            guard qty > 0 else { return nil }
            return CheckoutSummaryItem(
                name: item.name,
                quantity: qty,
                total: item.price * Double(qty)
            )
        }

        guard !selectedItems.isEmpty else {
            statusMessage = "Add at least one item."
            return
        }

        guard PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks) else {
            statusMessage = "Apple Pay is not available on this device."
            return
        }

        confirmationItems = selectedItems
        confirmationTotal = selectedItems.reduce(0) { $0 + $1.total }
        orderNumber = "FP2-\(Int.random(in: 100000...999999))"
        trackingNumber = "TRK-\(Int.random(in: 10000000...99999999))"

        let deliveryDate = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
        deliveryMessage = "Estimated delivery: \(deliveryDate.formatted(date: .abbreviated, time: .omitted))"

        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantIdentifier
        request.countryCode = "US"
        request.currencyCode = "USD"
        request.merchantCapabilities = [.threeDSecure]
        request.supportedNetworks = supportedNetworks

        var summaryItems: [PKPaymentSummaryItem] = selectedItems.map {
            PKPaymentSummaryItem(label: "\($0.name) x\($0.quantity)", amount: NSDecimalNumber(value: $0.total))
        }

        summaryItems.append(
            PKPaymentSummaryItem(
                label: "Final Project 2 Shop",
                amount: NSDecimalNumber(value: confirmationTotal)
            )
        )

        request.paymentSummaryItems = summaryItems

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self
        paymentController = controller

        controller.present { [weak self] presented in
            DispatchQueue.main.async {
                if !presented {
                    self?.statusMessage = "Could not open Apple Pay."
                }
            }
        }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        handler(PKPaymentAuthorizationResult(status: .success, errors: nil))
        statusMessage = "Payment authorized."
        showConfirmation = true
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss { [weak self] in
            DispatchQueue.main.async {
                self?.paymentController = nil
            }
        }
    }
}

struct ApplePayButton: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    final class Coordinator: NSObject {
        let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func tap() {
            action()
        }
    }
}

struct CheckoutConfirmationView: View {
    let items: [CheckoutSummaryItem]
    let total: Double
    let orderNumber: String
    let deliveryMessage: String
    let trackingNumber: String
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.green)

                Text("Payment Successful")
                    .font(.title.bold())

                Text("Your order has been placed.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Order #\(orderNumber)")
                        .font(.headline)

                    Text(deliveryMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Tracking: \(trackingNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)

                    Divider()

                    ForEach(items) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text("x\(item.quantity)")
                            Text("$\(item.total, specifier: "%.2f")")
                        }
                        .font(.subheadline)
                    }

                    Divider()

                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text("$\(total, specifier: "%.2f")")
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button("Done") {
                    onClose()
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Receipt")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ShopView: View {
    @State private var cart: [UUID: Int] = [:]
    @StateObject private var checkout = ApplePayCheckoutManager()

    private let shopItems: [ShopItem] = [
        ShopItem(
            name: "Band T-Shirt",
            price: 24.99,
            description: "Soft cotton tee with your favorite live event logo.",
            systemImage: "tshirt"
        ),
        ShopItem(
            name: "Sticker Pack",
            price: 6.99,
            description: "Set of 10 colorful music stickers.",
            systemImage: "seal"
        ),
        ShopItem(
            name: "Hoodie",
            price: 39.99,
            description: "Warm hoodie for concerts and late nights.",
            systemImage: "bag"
        ),
        ShopItem(
            name: "Poster",
            price: 14.99,
            description: "High-quality live show poster for your room.",
            systemImage: "photo"
        )
    ]

    private var cartCount: Int {
        cart.values.reduce(0, +)
    }

    private var cartTotal: Double {
        shopItems.reduce(0) { total, item in
            total + (Double(cart[item.id, default: 0]) * item.price)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Thank you for your purchase")
                            .font(.largeTitle.bold())

                        Text("Grab merch for the live events and music you love.")
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("Cart: \(cartCount) items")
                            Spacer()
                            Text("Total: $\(cartTotal, specifier: "%.2f")")
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        if !checkout.statusMessage.isEmpty {
                            Text(checkout.statusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        ForEach(shopItems) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.systemImage)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)

                                    Text(item.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text("$\(item.price, specifier: "%.2f")")
                                        .font(.subheadline.weight(.semibold))
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 8) {
                                    Stepper(
                                        "Qty \(cart[item.id, default: 0])",
                                        value: Binding(
                                            get: { cart[item.id, default: 0] },
                                            set: { cart[item.id] = max(0, min(10, $0)) }
                                        ),
                                        in: 0...10
                                    )
                                    .labelsHidden()

                                    Text("Qty: \(cart[item.id, default: 0])")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                    }

                    VStack(spacing: 12) {
                        ApplePayButton {
                            checkout.startCheckout(items: shopItems, quantities: cart)
                        }
                        .frame(height: 44)
                        .padding(.horizontal)

                        Text("Pay securely with Apple Pay")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical)
            }
            .navigationTitle("Shop")
            .sheet(isPresented: $checkout.showConfirmation) {
                CheckoutConfirmationView(
                    items: checkout.confirmationItems,
                    total: checkout.confirmationTotal,
                    orderNumber: checkout.orderNumber,
                    deliveryMessage: checkout.deliveryMessage,
                    trackingNumber: checkout.trackingNumber
                ) {
                    checkout.showConfirmation = false
                    checkout.statusMessage = "Thanks for your purchase!"
                    cart.removeAll()
                }
            }
        }
    }
}
#Preview {
    ContentView()
}
