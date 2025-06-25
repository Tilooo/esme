# ESME Maps
ESME Maps is a full-stack mapping application that allows users to discover and explore points of interest. The application features an interactive map interface with customizable map styles, category filtering, and location-based search capabilities.

## Features
- Interactive Map: Browse points of interest on an interactive map with multiple map style options
- Location Services: Find nearby points of interest based on your current location
- Dynamic Filtering: Users can filter points by category and search radius
- Live Routing: You can calculate and display routes for driving, walking, and cycling, complete with different colors
- Smart UX: The map automatically zooms to fit the route, and trip info is displayed
- Search Functionality: Search for specific points of interest by name or description
- Detailed Information: View comprehensive details about each point, including description, address, and distance from your location
- Responsive Design: Modern Material 3 UI that adapts to both light and dark themes, with zoom controls and a beautiful, pulsing live location marker
## Technology Stack
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
## Getting Started
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
## Future Enhancements
- User authentication and personalised favourites
- User reviews and ratings for points of interest
- Custom routes and navigation
- Offline map support
- Advanced filtering options
## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the LICENSE file for details.
