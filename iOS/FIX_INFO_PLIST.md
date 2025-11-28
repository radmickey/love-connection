# Fix Info.plist Conflict

## Problem
Xcode is trying to create Info.plist both automatically and from your file, causing a conflict.

## Solution

### Option 1: Use Manual Info.plist (Recommended)

1. **Remove Info.plist from Build Settings:**
   - Select project → Target "LoveConnection"
   - Go to **Build Settings** tab
   - Search for "Info.plist"
   - Find **Info.plist File** setting
   - **Clear/Delete** the value (make it empty)
   - Or set it to: `LoveConnection/Info.plist`

2. **Verify Info.plist is in project:**
   - Make sure `Info.plist` file exists in Project Navigator
   - It should be in `LoveConnection/` folder

3. **Clean and rebuild:**
   - Product → Clean Build Folder (⌘⇧K)
   - Product → Build (⌘B)

### Option 2: Use Auto-Generated Info.plist

1. **Delete Info.plist from project:**
   - Right-click `Info.plist` in Project Navigator
   - Delete → Move to Trash

2. **Configure in Build Settings:**
   - Select project → Target "LoveConnection"
   - Go to **Build Settings**
   - Search for "Info.plist"
   - Set **Generate Info.plist File** to **No**

3. **Add keys to Build Settings:**
   - Go to **Info** tab (not Build Settings)
   - Add custom keys:
     - `DEBUG_BACKEND_URL` = `http://localhost:8080`
     - `PRODUCTION_BACKEND_URL` = `https://api.loveconnection.app`

4. **Or use User-Defined Settings:**
   - In Build Settings, click **+** → Add User-Defined Setting
   - Add `DEBUG_BACKEND_URL` and `PRODUCTION_BACKEND_URL`

### Option 3: Quick Fix (Easiest)

1. **Remove Info.plist from Copy Bundle Resources:**
   - Select project → Target "LoveConnection"
   - Go to **Build Phases** tab
   - Expand **Copy Bundle Resources**
   - Find `Info.plist` in the list
   - Select it and click **-** to remove
   - **Keep the file in project**, just remove from copy phase

2. **Set Info.plist path in Build Settings:**
   - Build Settings → Search "Info.plist"
   - Set **Info.plist File** to: `LoveConnection/Info.plist`

3. **Clean and rebuild**

## Recommended Approach

Use **Option 1** - it's the most straightforward:
- Keep your Info.plist file
- Clear the auto-generation setting
- Point Build Settings to your file

