# Firebase Integration - WordTales App

## Overview
This document describes the Firebase Firestore integration implemented for the WordTales educational app.

## Architecture

### Authentication System
- **Custom Firestore-based authentication** (not using Firebase Auth)
- Teacher credentials stored directly in Firestore `teachers` collection
- Simple email/password validation against Firestore documents

### Collections Structure

#### 1. Teachers Collection (`teachers`)
```
teachers/
  └── default_teacher/
      ├── email: "teacher@wordtales.com"
      ├── password: "teacher123"
      ├── name: "Default Teacher"
      ├── createdAt: Timestamp
      └── isActive: boolean
```

#### 2. Students Collection (`students`)
```
students/
  └── {studentId}/
      ├── name: string
      ├── teacherId: string (reference to teacher)
      ├── createdAt: Timestamp
      ├── isActive: boolean
      └── levelProgress: {
          "1": {
            completed: boolean,
            score: number,
            totalItems: number,
            date: string
          },
          "2": { ... },
          "3": { ... },
          "4": { ... },
          "5": { ... }
        }
```

## Implementation Details

### Services Created

#### 1. AuthService (`lib/services/auth_service.dart`)
- `initializeDefaultTeacher()` - Creates default teacher account on app startup
- `loginTeacher(email, password)` - Validates teacher credentials
- `getTeacher(teacherId)` - Retrieves teacher data
- `updateTeacher(teacherId, data)` - Updates teacher profile
- `emailExists(email)` - Checks if email is already registered

#### 2. StudentService (`lib/services/student_service.dart`)
- `createStudent(name, teacherId)` - Creates new student with initial level progress
- `getStudentsByTeacher(teacherId)` - Fetches all students for a teacher
- `getStudent(studentId)` - Retrieves single student data
- `updateStudent(studentId, data)` - Updates student information
- `updateLevelProgress(studentId, level, score, totalItems)` - Updates level completion
- `deleteStudent(studentId)` - Soft deletes a student
- `getStudentCount(teacherId)` - Returns count of students
- `getLevelStats(teacherId, level)` - Calculates level statistics
- `streamStudentsByTeacher(teacherId)` - Real-time student updates stream

### Screen Updates

#### Login Screen (`lib/screens/login_screen.dart`)
- **Student Login**: Creates a new student document in Firestore
- **Teacher Login**: Validates credentials against Firestore teachers collection
- Loading states with progress indicators
- Error handling with toast notifications

#### Teacher Home Screen (`lib/screens/teacher.home_screen.dart`)
- Loads students from Firestore on initialization
- Displays loading indicator while fetching data
- FloatingActionButton to add new students
- Real-time student management
- Level statistics calculated from Firestore data

### Main App Initialization (`lib/main.dart`)
- Firebase initialized on app startup
- Default teacher account created automatically if it doesn't exist

## Default Credentials

### Teacher Account
- **Email**: `teacher@wordtales.com`
- **Password**: `teacher123`
- **ID**: `default_teacher`

## Features Implemented

### For Teachers:
1. ✅ Login with email/password
2. ✅ View all students assigned to them
3. ✅ Add new students via FAB
4. ✅ Track student progress across 5 levels
5. ✅ View level statistics (completion rate, average scores)
6. ✅ Search students by name
7. ✅ Manage level content (add/edit/delete words and sentences)

### For Students:
1. ✅ Quick login with just name
2. ✅ Automatic student document creation in Firestore
3. ✅ Progress tracking across 5 levels
4. ✅ Level completion data stored in Firestore

## Data Flow

### Student Creation Flow:
1. User enters student name in login screen
2. `StudentService.createStudent()` called
3. New document created in `students` collection with:
   - Student name
   - Teacher ID (default_teacher)
   - Initial level progress (all levels locked)
   - Timestamp
4. Student navigated to app

### Teacher Login Flow:
1. Teacher enters email and password
2. `AuthService.loginTeacher()` queries Firestore
3. If credentials match, teacher data returned
4. Teacher navigated to dashboard with their ID and name

### Student Progress Update:
1. Student completes a level
2. `StudentService.updateLevelProgress()` called
3. Firestore document updated with:
   - Completion status
   - Score achieved
   - Total items in level
   - Completion date

## Security Considerations

⚠️ **Important**: This implementation uses plain text passwords stored in Firestore. For production:
1. Implement proper password hashing (bcrypt, argon2)
2. Use Firebase Authentication instead of custom auth
3. Add Firestore security rules
4. Implement role-based access control
5. Add input validation and sanitization

## Firestore Security Rules (Recommended)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Teachers collection - only authenticated teachers can read/write
    match /teachers/{teacherId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == teacherId;
    }
    
    // Students collection - teachers can manage their students
    match /students/{studentId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.teacherId == request.auth.uid;
    }
  }
}
```

## Testing

### Test Teacher Login:
1. Run the app
2. Click "Teacher Login"
3. Enter: `teacher@wordtales.com` / `teacher123`
4. Should navigate to Teacher Dashboard

### Test Student Creation:
1. Run the app
2. Enter any student name
3. Click "Continue"
4. Check Firestore console - new student document should be created

## Dependencies

```yaml
dependencies:
  firebase_core: ^4.1.0
  cloud_firestore: ^6.0.1
  fluttertoast: ^9.0.0
```

## Future Enhancements

1. Add Firebase Authentication for better security
2. Implement real-time listeners for live updates
3. Add offline support with Firestore caching
4. Implement batch operations for better performance
5. Add analytics to track student engagement
6. Export student progress reports
7. Add parent accounts to view student progress
8. Implement multi-teacher support
9. Add profile pictures using Firebase Storage
10. Implement push notifications for achievements

## Troubleshooting

### Issue: Default teacher not created
- **Solution**: Check Firebase console for proper initialization
- Verify `firebase_options.dart` is configured correctly

### Issue: Students not loading
- **Solution**: Check Firestore permissions
- Verify network connectivity
- Check console for error messages

### Issue: Login fails
- **Solution**: Verify credentials match Firestore data
- Check if teacher document exists in Firestore
- Ensure `isActive` field is `true`

## Contact

For questions or issues, refer to the main project documentation.
