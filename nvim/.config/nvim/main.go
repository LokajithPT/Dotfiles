package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"sync"
	"time"
)

// Data structures
type User struct {
	CurrentStreak   int       `json:"currentStreak"`
	KeystrokesToday int       `json:"keystrokesToday"`
	CurrentLevel    int       `json:"currentLevel"`
	FreezesLeft     int       `json:"freezesLeft"`
	StreakStatus    string    `json:"streakStatus"` // pending, approved, rejected
	LastActivity    time.Time `json:"lastActivity"`
}

type Project struct {
	ID     int    `json:"id"`
	Name   string `json:"name"`
	Status string `json:"status"`
}

type Task struct {
	ID          int    `json:"id"`
	Description string `json:"description"`
	Project     string `json:"project"`
	Completed   bool   `json:"completed"`
}

type Activity struct {
	Type      string  `json:"type"`
	Message   string  `json:"message"`
	Time      string  `json:"time"`
	Timestamp string  `json:"timestamp,omitempty"`
	FilePath  string  `json:"file_path,omitempty"`
	Action    string  `json:"action,omitempty"`
	Content   string  `json:"content,omitempty"`
	Line      int     `json:"line,omitempty"`
	WPM       float64 `json:"wpm,omitempty"`
	Color     string  `json:"color,omitempty"`
}

type DetailedActivity struct {
	ID        int     `json:"id"`
	Timestamp string  `json:"timestamp"`
	FilePath  string  `json:"file_path"`
	Action    string  `json:"action"`
	Content   string  `json:"content,omitempty"`
	Line      int     `json:"line,omitempty"`
	WPM       float64 `json:"wpm,omitempty"`
	Color     string  `json:"color"`
}

type DashboardData struct {
	User       User       `json:"user"`
	Projects   []Project  `json:"projects"`
	Tasks      []Task     `json:"tasks"`
	Activities []Activity `json:"activities"`
}

// Global data store
var (
	data               DashboardData
	mutex              sync.RWMutex
	nextID             = 1
	detailedActivities []DetailedActivity
)

// Initialize mock data
func init() {
	data = DashboardData{
		User: User{
			CurrentStreak:   7,
			KeystrokesToday: 2847,
			CurrentLevel:    12,
			FreezesLeft:     3,
			StreakStatus:    "pending",
			LastActivity:    time.Now(),
		},
		Projects: []Project{
			{ID: 1, Name: "DuoLevelling CLI", Status: "active"},
		},
		Tasks: []Task{
			{ID: 1, Description: "Implement Floating Window", Project: "DuoLevelling CLI", Completed: false},
			{ID: 2, Description: "Add WebSocket support", Project: "DuoLevelling CLI", Completed: false},
		},
		Activities: []Activity{
			{Type: "streak", Message: "7 day streak achieved!", Time: "2 hours ago"},
			{Type: "task", Message: "Completed: UI Implementation", Time: "4 hours ago"},
			{Type: "level", Message: "Reached Level 12!", Time: "Yesterday"},
		},
	}
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "Welcome to DuoLevelling Server!")
}

func hello(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	if name == "" {
		name = "Loki"
	}

	fmt.Fprintf(w, "hello %s ", name)
}

func heartbeatHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, `{"status": "OK"}`)
}

func dashboardHandler(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "/home/skedaddle/code/duolevelling/dashboard.html")
}

// API Handlers
func apiDashboardHandler(w http.ResponseWriter, r *http.Request) {
	mutex.RLock()
	defer mutex.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

func apiKeystrokesHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		var req struct {
			Keystrokes int `json:"keystrokes"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		mutex.Lock()
		data.User.KeystrokesToday += req.Keystrokes
		data.User.LastActivity = time.Now()
		data.Activities = append([]Activity{
			{Type: "task", Message: fmt.Sprintf("Added %d keystrokes", req.Keystrokes), Time: "Just now"},
		}, data.Activities...)
		mutex.Unlock()

		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{"status": "success"})
	}
}

func apiStreakApproveHandler(w http.ResponseWriter, r *http.Request) {
	mutex.Lock()
	defer mutex.Unlock()

	data.User.StreakStatus = "approved"
	data.User.CurrentStreak++ // Increment streak when approved
	data.Activities = append([]Activity{
		{Type: "streak", Message: "Streak approved by admin!", Time: "Just now"},
	}, data.Activities...)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "approved"})
}

func apiStreakRejectHandler(w http.ResponseWriter, r *http.Request) {
	mutex.Lock()
	defer mutex.Unlock()

	data.User.StreakStatus = "rejected"
	data.Activities = append([]Activity{
		{Type: "streak", Message: "Streak rejected by admin", Time: "Just now"},
	}, data.Activities...)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "rejected"})
}

func apiStreakGrantFreezeHandler(w http.ResponseWriter, r *http.Request) {
	mutex.Lock()
	defer mutex.Unlock()

	if data.User.FreezesLeft > 0 {
		data.User.FreezesLeft--
		data.Activities = append([]Activity{
			{Type: "freeze", Message: "Streak freeze granted by admin", Time: "Just now"},
		}, data.Activities...)
	} else {
		http.Error(w, "No freezes left", http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "freeze granted"})
}

func apiProjectsHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		mutex.RLock()
		json.NewEncoder(w).Encode(data.Projects)
		mutex.RUnlock()

	case "POST":
		var req struct {
			Name string `json:"name"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		mutex.Lock()
		project := Project{
			ID:     nextID,
			Name:   req.Name,
			Status: "active",
		}
		data.Projects = append(data.Projects, project)
		nextID++

		data.Activities = append([]Activity{
			{Type: "task", Message: fmt.Sprintf("New project added: %s", req.Name), Time: "Just now"},
		}, data.Activities...)
		mutex.Unlock()

		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(project)
	}
}

func apiTasksHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		mutex.RLock()
		json.NewEncoder(w).Encode(data.Tasks)
		mutex.RUnlock()

	case "POST":
		var req struct {
			Description string `json:"description"`
			Project     string `json:"project"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		mutex.Lock()
		task := Task{
			ID:          nextID,
			Description: req.Description,
			Project:     req.Project,
			Completed:   false,
		}
		data.Tasks = append(data.Tasks, task)
		nextID++

		data.Activities = append([]Activity{
			{Type: "task", Message: fmt.Sprintf("New task added: %s", req.Description), Time: "Just now"},
		}, data.Activities...)
		mutex.Unlock()

		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(task)
	}
}

func apiTasksUpdateHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "PUT" {
		idStr := r.URL.Query().Get("id")
		id, err := strconv.Atoi(idStr)
		if err != nil {
			http.Error(w, "Invalid task ID", http.StatusBadRequest)
			return
		}

		var req struct {
			Completed bool `json:"completed"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		mutex.Lock()
		defer mutex.Unlock()

		for i, task := range data.Tasks {
			if task.ID == id {
				data.Tasks[i].Completed = req.Completed
				message := "Task completed"
				if !req.Completed {
					message = "Task marked as incomplete"
				}
				data.Activities = append([]Activity{
					{Type: "task", Message: message, Time: "Just now"},
				}, data.Activities...)
				break
			}
		}

		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{"status": "updated"})
	}
}

func apiActivityHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		var activity DetailedActivity
		if err := json.NewDecoder(r.Body).Decode(&activity); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		// Set color based on action type
		switch activity.Action {
		case "typing", "typing_session_end", "save":
			activity.Color = "green"
		case "copy", "paste":
			activity.Color = "red"
		case "open":
			activity.Color = "blue"
		default:
			activity.Color = "gray"
		}

		activity.ID = nextID
		nextID++

		mutex.Lock()
		defer mutex.Unlock()

		detailedActivities = append(detailedActivities, activity)

		// Keep only last 100 activities to avoid memory issues
		if len(detailedActivities) > 100 {
			detailedActivities = detailedActivities[len(detailedActivities)-100:]
		}

		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(activity)
	}
}

func apiDetailedActivitiesHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "GET" {
		mutex.RLock()
		defer mutex.RUnlock()

		// Reverse to show latest first
		reversed := make([]DetailedActivity, len(detailedActivities))
		for i, activity := range detailedActivities {
			reversed[len(detailedActivities)-1-i] = activity
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(reversed)
	}
}

func apiSetManualStreakHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		var req struct {
			Streak int `json:"streak"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		mutex.Lock()
		defer mutex.Unlock()

		data.User.CurrentStreak = req.Streak
		data.Activities = append([]Activity{
			{Type: "streak", Message: fmt.Sprintf("Streak manually set to %d", req.Streak), Time: "Just now"},
		}, data.Activities...)

		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{"status": "updated"})
	}
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/", homeHandler)
	mux.HandleFunc("/hello", hello)
	mux.HandleFunc("/heartbeat", heartbeatHandler)
	mux.HandleFunc("/dash1", dashboardHandler)

	// API routes
	mux.HandleFunc("/api/dashboard", apiDashboardHandler)
	mux.HandleFunc("/api/keystrokes", apiKeystrokesHandler)
	mux.HandleFunc("/api/streak/approve", apiStreakApproveHandler)
	mux.HandleFunc("/api/streak/reject", apiStreakRejectHandler)
	mux.HandleFunc("/api/streak/grant-freeze", apiStreakGrantFreezeHandler)
	mux.HandleFunc("/api/streak/set", apiSetManualStreakHandler)
	mux.HandleFunc("/api/projects", apiProjectsHandler)
	mux.HandleFunc("/api/tasks", apiTasksHandler)
	mux.HandleFunc("/api/tasks/update", apiTasksUpdateHandler)
	mux.HandleFunc("/api/activity", apiActivityHandler)
	mux.HandleFunc("/api/activities", apiDetailedActivitiesHandler)

	fmt.Println("server running on localhost:8080")
	fmt.Println("Dashboard available at: http://localhost:8080/dash1")
	fmt.Println("API available at: http://localhost:8080/api/")
	fmt.Println("Dashboard available at: http://localhost:8080/dash1")
	log.Fatal(http.ListenAndServe(":8080", mux))
}
