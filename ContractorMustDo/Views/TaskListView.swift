//
//  TaskListView.swift
//  ContractorMustDo
//
//  Main task list view with filtering and grouping.
//

import SwiftUI
import SwiftData

// MARK: - Task List View

/// Main view displaying the task list with filtering and sorting options.
struct TaskListView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settingsManager: SettingsManager

    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]

    @StateObject private var viewModel = TaskListViewModel()

    @State private var showingQuickAdd = false
    @State private var quickAddText = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if tasks.isEmpty {
                    emptyStateView
                } else {
                    taskListContent
                }
            }
            .navigationTitle(Strings.Tab.tasks)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    addButton
                }
            }
            .searchable(text: $viewModel.searchQuery, prompt: "Search tasks")
            .sheet(isPresented: $viewModel.showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
            .sheet(item: $viewModel.selectedTask) { task in
                TaskDetailView(task: task, viewModel: viewModel)
            }
            .alert(
                Strings.Common.error,
                isPresented: .constant(viewModel.errorMessage != nil)
            ) {
                Button(Strings.Common.ok) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text(Strings.Task.noTasks)
                .font(.title2)
                .fontWeight(.semibold)

            Text(Strings.Task.noTasksSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                viewModel.showingAddTask = true
            } label: {
                Label(Strings.Task.addTask, systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
    }

    private var taskListContent: some View {
        VStack(spacing: 0) {
            // Quick add bar
            quickAddBar

            // Task list
            List {
                ForEach(viewModel.groupedTasks(tasks), id: \.section) { group in
                    Section {
                        ForEach(group.tasks) { task in
                            TaskRowView(task: task, viewModel: viewModel)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteTask(task, context: modelContext)
                                    } label: {
                                        Label(Strings.Common.delete, systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        viewModel.toggleCompletion(task, context: modelContext)
                                    } label: {
                                        Label(
                                            task.isCompleted ? "Undo" : Strings.Task.markComplete,
                                            systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                        )
                                    }
                                    .tint(task.isCompleted ? .orange : .green)
                                }
                        }
                    } header: {
                        HStack {
                            Circle()
                                .fill(group.section.color)
                                .frame(width: 8, height: 8)
                            Text(group.section.displayName)
                                .font(.headline)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var quickAddBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .foregroundStyle(.secondary)

            TextField(Strings.NaturalLanguage.quickAdd, text: $quickAddText)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .onSubmit {
                    if !quickAddText.isEmpty {
                        viewModel.addTaskFromNaturalLanguage(quickAddText, context: modelContext)
                        quickAddText = ""
                    }
                }

            if !quickAddText.isEmpty {
                Button {
                    viewModel.addTaskFromNaturalLanguage(quickAddText, context: modelContext)
                    quickAddText = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
    }

    private var filterMenu: some View {
        Menu {
            Section("Filter") {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    Button {
                        viewModel.filter = filter
                    } label: {
                        HStack {
                            Text(filter.displayName)
                            if viewModel.filter == filter {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Section("Sort") {
                ForEach(TaskSortOrder.allCases, id: \.self) { sort in
                    Button {
                        viewModel.sortOrder = sort
                    } label: {
                        HStack {
                            Text(sort.displayName)
                            if viewModel.sortOrder == sort {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Section {
                Toggle(isOn: $viewModel.showCompleted) {
                    Text("Show Completed")
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }

    private var addButton: some View {
        Button {
            viewModel.showingAddTask = true
        } label: {
            Image(systemName: "plus")
        }
    }
}

// MARK: - Preview

#Preview {
    TaskListView()
        .modelContainer(for: TaskItem.self, inMemory: true)
        .environmentObject(NotificationService.shared)
        .environmentObject(SettingsManager.shared)
}
