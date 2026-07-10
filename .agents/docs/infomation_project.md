(*) 3.1. Capstone Project name: 
English: BoardVerse - An Operation and Matchmaking Platform for Board Game Cafes
Vietnamese: BoardVerse - Nền tảng Vận hành và Ghép đội dành cho Quán Board Game
a. Context:
Board game cafes currently face difficulties in managing revenue across complex time slots and controlling the risk of losing thousands of small game components. For players, they often struggle with a lack of teammates and difficulty finding groups with similar interests and skill levels (Elo) in their vicinity. These issues lead to operational inefficiencies for cafe owners and a fragmented experience for the board game community.
Functional requirement :
Player Mobile App:
● Authentication: Users can register, login, and manage personal profiles (interests, Elo rating, Karma points).
● Discovery: Users can search for partner cafes, view real-time table availability, and browse the available game list of each cafe.
● Matchmaking: Users can create a Lobby with specific conditions: game type, search radius, minimum skill level, and desired time slot.
● Booking: Allows users to reserve tables at partner cafes. Once an online Lobby is full, the system automatically converts the match into a physical table reservation.
● Workflow Logic: Automatically checks real-time table and game availability. Upon successful reservation, it triggers and initializes a real-time billing session on the cafe's Web POS interface.
● Notifications: The system automatically suggests and sends Push Notifications to suitable players in the area to invite them to join the Lobby.
● Workflow Logic: Once the Lobby is full, the system cross-checks the cafe's status: Suggests "Walk-in" if tables/games are available immediately, or "Booking" if the cafe is currently at full capacity.
● Reputation System: Users can perform cross-ratings of other members' attitudes after a session for the system to update Karma points.
● Tracking: Users can view play history, ranking statistics, and earned badges.
Cafe POS & Management Web System:
● Registration: Cafe Owners can submit a registration request to join the platform by providing their business details, location, and operating hours for Admin approval.
● Shift & Table Management: Staff can open work shifts and view an intuitive table map with real-time statuses (empty, in-use, reserved, ongoing event)
● Check-in: Staff can open a table by scanning a QR code for walk-in customers or checking in booking IDs for reserved customers.
● Game Tracking: Staff scan game barcodes to assign them to active tables; the system automatically starts tracking usage time.
● Inventory Control: When a game is returned/exchanged, the POS screen displays a core component checklist. Staff confirm any missing or damaged items.
● Billing: The system automatically generates invoices including total playtime (based on blocks or time frames) and component penalty fees.
● Configuration: Managers can set up the board game catalog, component checklists, and compensation rates for each component type.
● Operational Rules: Managers configure booking rules (lead time, cancellation fees), available table counts, and approve event requests.
● Analytics: Managers view detailed reports on occupancy rates, revenue per shift, most-played games, and component loss frequency.
● Event Management: Organizers create tournament/event campaigns, setting rules, participant limits, and minimum Elo requirements.
● Venue Booking: Organizers send venue requests to partner cafes and track approval status.
● Attendance & Results: Organizers manage registration lists, perform check-ins, and input results for the system to update players' Elo ratings.
Admin Web System:
● Partner Onboarding: Admin can review, verify, and approve or reject new cafe registration requests before they are listed on the platform.
● Account Management: Admin manages all accounts: Players, Cafe Managers, Staff
● System Monitoring: Admin monitors Karma logs, automatically warning or suspending accounts for frequent "no-shows" or toxic behavior.
● Master Configuration: Admin adjusts core system settings: Elo calculation weights, Karma penalty thresholds, and global matchmaking rules.
● Platform Analytics: Admin views overall reports on matchmaking success rates, total bookings, and the operational performance of partner cafes.
Non-functional requirement:
● Performance: The system API response time must be less than 500ms.
● Availability: The system guarantees 99.9% uptime with an auto-failover mechanism.
● Security: All sensitive data and user passwords must be encrypted using high-security hashing algorithms.
● Usability: The POS and Management Web apps must be responsive, optimizing operations on Tablets and Mobile devices.
 (*) 3.2. Main proposal content (including result and product)   
Proposed Solutions:
● Develop a specialized POS system with dynamic component inventory features and automated multi-tier billing for Boardgame (combining hourly rates and penalty fees).
● Integrate a smart matchmaking algorithm based on location, skill level (Elo), and reputation (Karma) to automate the process of finding groups.
● Provide a centralized booking and event coordination system to optimize the operational capacity of partner cafes.
Products (Expected Deliverables):
● Mobile App for BoardVerse Players.
● Web App (POS & Management) for Cafe Partners.
● Web API for the System.
● Web Admin for Administrators and Event Organizers.

