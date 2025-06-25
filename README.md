# ESME Maps 🗺️

**Esme Maps** is a full-stack, feature-rich interactive mapping application designed for modern exploration. Built with a powerful **Python (Django)** backend and a beautiful, high-performance **Flutter** frontend, Esme allows users to discover points of interest, get live directions, and interact with the map in an intuitive and dynamic way.

This project showcases a complete full-stack architecture, from backend API design to a polished, cross-platform user interface.

---

## ✨ Core Features

Esme is packed with features that make it a powerful and versatile mapping tool.

#### 📍 **Interactive Mapping & Navigation**
*   **Live On-Map Routing:** Calculate and display optimal routes directly on the map for **Driving, Cycling, and Walking**. Routes are color-coded for clarity.
*   **Smart Route-Fitting:** The map view automatically zooms and pans to perfectly frame the entire calculated route.
*   **Trip Information:** Instantly see the estimated **distance and travel time** for any generated route.
*   **Pulsing Live Location:** A beautifully animated marker clearly indicates the user's current position.
*   **Multiple Map Styles:** Instantly switch between OpenStreetMap, a detailed Topographic map, and a cycling-focused view (CyclOSM).

#### 🔍 **Dynamic Discovery & Search**
*   **Reverse Geocoding:** **Long-press anywhere** on the map to instantly discover the real-world address of that spot.
*   **Visual Search Radius:** A dynamic circle on the map provides clear visual feedback for the current search area.
*   **Advanced Search & Filtering:** Quickly find specific locations by name and filter points of interest by category.

#### 🎨 **Polished User Interface (UI/UX)**
*   **Animated Splash Screen:** A beautiful, cinematic splash screen provides a professional first impression.
*   **Modern Material 3 Design:** A clean, responsive UI that adapts to both light and dark system themes.
*   **Intuitive Controls:** Dedicated on-map buttons for zooming and a clean, clutter-free AppBar.
*   **Detailed Information Sheets:** Professionally designed, draggable bottom sheets display comprehensive details for each point of interest.
## 🛠️ Technology Stack
### Frontend
- Flutter: Cross-platform UI framework for building mobile applications
- flutter_map: Map visualisation library for Flutter
- geolocator: Location services and permissions handling
- http: API communication
### Backend
- Django: Python web framework for the backend API
- Django REST Framework: RESTful API development
- SQLite: Database for development (can be configured for PostgreSQL in production)
## Project Structure

## API Endpoints
- /api/points/ - List and create points of interest
- /api/categories/ - List and create categories
- /api/nearby/ - Find points near a specific location
- /api/points/search/ - Search for points by name or description
## 🚀 Getting Started
### Prerequisites
- Flutter SDK (2.12.0 or higher)
- Python 3.8+ with pip
- Git
### Backend Setup
1. Clone the repository
   
   ```
   git clone https://github.com/Tilooo/esme.git
   cd esme
   ```
2. Create and activate a virtual environment
   
   ```
   python -m venv .venv
   .venv\Scripts\activate  # On Windows
   source .venv/bin/activate  # On macOS/Linux
   ```
3. Install dependencies
   
   ```
   pip install -r requirements.txt
   ```
4. Run migrations
   
   ```
   python manage.py migrate
   ```
5. Start the development server
   
   ```
   python manage.py runserver
   ```
### Frontend Setup
1. Navigate to the frontend directory
   
   ```
   cd frontend
   ```
2. Install Flutter dependencies
   
   ```
   flutter pub get
   ```
3. Run the application
   
   ```
   flutter run
   ```
## 🔮 Future Enhancements

*   **User Authentication:** Allow users to create accounts and save favorite locations.
*   **User-Generated Content:** Enable users to add their own points of interest or leave reviews.
*   **Offline Support:** Cache map tiles and data for use without an internet connection.
## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Please feel free to submit a Pull Request or open an issue.

---

## 📜 License

This project is licensed under the MIT License - see the `LICENSE` file for details.
