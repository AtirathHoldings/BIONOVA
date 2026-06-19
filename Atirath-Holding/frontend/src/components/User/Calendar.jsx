// src/components/Calendar.jsx
import React, { useState } from "react";
import Sidebar from "../Sidebar";
import "../../styles/calendar.css";

import {
  ChevronLeft,
  ChevronRight,
  Plus,
  Search,
  Bell,
  Mail,
  Filter,
  Calendar as CalendarIcon,
  Clock,
  MapPin,
  Users,
  MoreVertical,
  Edit,
  Trash2,
  X,
  Check
} from "lucide-react";

const Calendar = ({ userRole, onLogout }) => {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [view, setView] = useState("month");
  const [selectedDate, setSelectedDate] = useState(null);
  const [showEventModal, setShowEventModal] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);

  // Get current month and year
  const currentMonth = currentDate.getMonth();
  const currentYear = currentDate.getFullYear();

  // Get days in month
  const getDaysInMonth = (year, month) => {
    return new Date(year, month + 1, 0).getDate();
  };

  // Get first day of month
  const getFirstDayOfMonth = (year, month) => {
    return new Date(year, month, 1).getDay();
  };

  const daysInMonth = getDaysInMonth(currentYear, currentMonth);
  const firstDay = getFirstDayOfMonth(currentYear, currentMonth);

  // Events data
  const [events, setEvents] = useState([
    {
      id: 1,
      title: "Team Meeting",
      date: "2026-06-18",
      time: "10:00 AM",
      location: "Conference Room A",
      attendees: 8,
      type: "meeting",
      color: "#3b82f6"
    },
    {
      id: 2,
      title: "Project Deadline",
      date: "2026-06-20",
      time: "05:00 PM",
      location: "Online",
      attendees: 12,
      type: "deadline",
      color: "#ef4444"
    },
    {
      id: 3,
      title: "Client Presentation",
      date: "2026-06-22",
      time: "02:00 PM",
      location: "Client Office",
      attendees: 5,
      type: "meeting",
      color: "#8b5cf6"
    },
    {
      id: 4,
      title: "Design Review",
      date: "2026-06-25",
      time: "11:00 AM",
      location: "Design Studio",
      attendees: 4,
      type: "review",
      color: "#f59e0b"
    },
    {
      id: 5,
      title: "Sprint Planning",
      date: "2026-06-28",
      time: "09:30 AM",
      location: "Meeting Room B",
      attendees: 10,
      type: "planning",
      color: "#10b981"
    }
  ]);

  // Upcoming events
  const upcomingEvents = [
    {
      id: 1,
      title: "Team Meeting",
      date: "Today, 10:00 AM",
      type: "meeting"
    },
    {
      id: 2,
      title: "Project Deadline",
      date: "Tomorrow, 5:00 PM",
      type: "deadline"
    },
    {
      id: 3,
      title: "Client Call",
      date: "Jun 20, 2:00 PM",
      type: "call"
    }
  ];

  const months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  const weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  const getEventsForDate = (date) => {
    const dateStr = `${currentYear}-${String(currentMonth + 1).padStart(2, '0')}-${String(date).padStart(2, '0')}`;
    return events.filter(event => event.date === dateStr);
  };

  const getEventTypeIcon = (type) => {
    switch(type) {
      case "meeting": return "👥";
      case "deadline": return "⏰";
      case "review": return "📝";
      case "planning": return "📊";
      case "call": return "📞";
      default: return "📅";
    }
  };

  const previousMonth = () => {
    setCurrentDate(new Date(currentYear, currentMonth - 1, 1));
  };

  const nextMonth = () => {
    setCurrentDate(new Date(currentYear, currentMonth + 1, 1));
  };

  const goToToday = () => {
    setCurrentDate(new Date());
  };

  const handleDateClick = (date) => {
    setSelectedDate(date);
    setShowEventModal(true);
  };

  return (
    <div className="calendar-layout">
      <Sidebar userRole={userRole} />

      <main className="calendar-main">
        {/* Top Bar */}
        <div className="calendar-top-bar">
          <div className="calendar-page-title">
            <h1>Calendar</h1>
            <p>Manage your schedule and events</p>
          </div>

          <div className="calendar-top-actions">
            <div className="calendar-search">
              <Search size={18} />
              <input type="text" placeholder="Search events..." />
            </div>

            <button className="calendar-icon-btn">
              <Bell size={18} />
            </button>

            <button className="calendar-icon-btn">
              <Mail size={18} />
            </button>

            <button className="calendar-primary-btn" onClick={() => setShowEventModal(true)}>
              <Plus size={16} />
              Create Event
            </button>

            <div className="calendar-profile">
              <button 
                className="calendar-profile-btn"
                onClick={() => setShowProfileMenu(!showProfileMenu)}
              >
                <div className="profile-avatar">
                  <span>JD</span>
                </div>
                <span className="profile-name">John Doe</span>
              </button>

              {showProfileMenu && (
                <div className="profile-dropdown-menu">
                  <button>Profile</button>
                  <button>Settings</button>
                  <button onClick={onLogout}>Logout</button>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Calendar Controls */}
        <div className="calendar-controls">
          <div className="calendar-nav">
            <button onClick={previousMonth} className="nav-btn">
              <ChevronLeft size={20} />
            </button>
            <button onClick={goToToday} className="today-btn">Today</button>
            <button onClick={nextMonth} className="nav-btn">
              <ChevronRight size={20} />
            </button>
            <h2>{months[currentMonth]} {currentYear}</h2>
          </div>

          <div className="calendar-views">
            <button className={`view-btn ${view === "month" ? "active" : ""}`} onClick={() => setView("month")}>
              Month
            </button>
            <button className={`view-btn ${view === "week" ? "active" : ""}`} onClick={() => setView("week")}>
              Week
            </button>
            <button className={`view-btn ${view === "day" ? "active" : ""}`} onClick={() => setView("day")}>
              Day
            </button>
          </div>
        </div>

        {/* Main Calendar Grid */}
        <div className="calendar-grid-container">
          <div className="calendar-weekdays">
            {weekDays.map(day => (
              <div key={day} className="weekday-cell">{day}</div>
            ))}
          </div>

          <div className="calendar-days-grid">
            {/* Empty cells for days before month starts */}
            {Array.from({ length: firstDay }).map((_, i) => (
              <div key={`empty-${i}`} className="calendar-day empty"></div>
            ))}

            {/* Actual days of the month */}
            {Array.from({ length: daysInMonth }).map((_, i) => {
              const day = i + 1;
              const dayEvents = getEventsForDate(day);
              const isToday = day === new Date().getDate() && 
                             currentMonth === new Date().getMonth() && 
                             currentYear === new Date().getFullYear();

              return (
                <div 
                  key={day} 
                  className={`calendar-day ${isToday ? "today" : ""} ${selectedDate === day ? "selected" : ""}`}
                  onClick={() => handleDateClick(day)}
                >
                  <div className="day-number">{day}</div>
                  <div className="day-events">
                    {dayEvents.slice(0, 2).map(event => (
                      <div key={event.id} className="day-event" style={{ background: event.color + "20", color: event.color }}>
                        {event.title}
                      </div>
                    ))}
                    {dayEvents.length > 2 && (
                      <div className="more-events">+{dayEvents.length - 2} more</div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Upcoming Events Sidebar */}
        <div className="upcoming-events-sidebar">
          <div className="sidebar-header">
            <h3>Upcoming Events</h3>
            <Filter size={18} />
          </div>

          <div className="events-list">
            {upcomingEvents.map(event => (
              <div key={event.id} className="event-item">
                <div className="event-icon">{getEventTypeIcon(event.type)}</div>
                <div className="event-details">
                  <div className="event-title">{event.title}</div>
                  <div className="event-date">{event.date}</div>
                </div>
                <button className="event-more">
                  <MoreVertical size={16} />
                </button>
              </div>
            ))}
          </div>

          <button className="view-all-btn">View All Events</button>
        </div>
      </main>

      {/* Event Modal */}
      {showEventModal && (
        <div className="modal-overlay" onClick={() => setShowEventModal(false)}>
          <div className="modal-container" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Add New Event</h3>
              <button className="modal-close" onClick={() => setShowEventModal(false)}>
                <X size={18} />
              </button>
            </div>
            <div className="modal-body">
              <div className="form-field">
                <label>Event Title</label>
                <input type="text" placeholder="Enter event title" />
              </div>
              
              <div className="form-row">
                <div className="form-field">
                  <label>Date</label>
                  <input type="date" />
                </div>
                <div className="form-field">
                  <label>Time</label>
                  <input type="time" />
                </div>
              </div>

              <div className="form-field">
                <label>Location</label>
                <input type="text" placeholder="Enter location" />
              </div>

              <div className="form-field">
                <label>Event Type</label>
                <select>
                  <option>Meeting</option>
                  <option>Deadline</option>
                  <option>Review</option>
                  <option>Planning</option>
                  <option>Call</option>
                </select>
              </div>

              <div className="form-field">
                <label>Description</label>
                <textarea rows="3" placeholder="Event description..."></textarea>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-cancel" onClick={() => setShowEventModal(false)}>Cancel</button>
              <button className="btn-create">Create Event</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Calendar;