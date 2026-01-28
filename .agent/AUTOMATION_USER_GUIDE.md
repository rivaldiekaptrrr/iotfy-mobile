# 🚀 Automation System - Quick Start Guide

## 📱 How to Create Your First Automation Rule

### **Step 1: Open Rule Manager**
1. Go to your dashboard
2. Tap the menu (☰)
3. Select **"Rule Engine"**

---

### **Step 2: Add a New Rule**
1. Tap the **"+ Add Rule"** button (bottom right)
2. Enter a descriptive name (e.g., "Auto Fan Control")

---

### **Step 3: Choose Trigger Type**

#### **Option A: Widget Trigger** (Sensor-Based)
Best for: Automatic responses to sensor values

1. Select **"Widget"** trigger
2. Choose source widget (e.g., "Temperature Gauge")
3. Select operator (e.g., "> Greater")
4. Enter threshold value (e.g., "30")

**Example**: IF Temperature > 30°C

---

#### **Option B: Manual Trigger** (Button-Based)
Best for: On-demand actions

1. Select **"Manual"** trigger
2. That's it! No additional configuration needed

**Example**: Emergency shutdown button

---

#### **Option C: Schedule Trigger** (Time-Based)
Best for: Recurring or scheduled actions

1. Select **"Schedule"** trigger
2. Choose schedule type:
   - **Once**: Pick date & time
   - **Daily**: Pick time (e.g., 08:00)
   - **Weekly**: Pick days + time
   - **Interval**: Enter minutes (e.g., 30)

**Example**: Turn on lights every day at 7:00 AM

---

### **Step 4: Configure Actions**

#### **✅ Control Another Widget** (NEW!)
Automatically control other widgets

1. Check **"Control Another Widget"**
2. Select target widget (e.g., "Fan Toggle")
3. Enter payload (e.g., "ON", "OFF", "50")

---

#### **✅ Show Notification**
Get notified when rule triggers

1. Check **"Show Notification"**
2. (Optional) Enter custom title

---

#### **✅ Publish MQTT Message**
Send custom MQTT commands

1. Check **"Publish MQTT Message"**
2. Enter topic (e.g., "home/fan")
3. Enter payload (e.g., "ON")

---

### **Step 5: Set Severity**
Choose alarm severity:
- **Minor**: Low priority
- **Major**: Medium priority
- **Critical**: High priority

---

### **Step 6: Save**
Tap **"Save"** button

Your rule is now active! ✅

---

## 🎯 Common Use Cases

### **1. Temperature Control**
```
Name: Auto Fan Control
Trigger: Widget (Temperature > 30)
Action: Control Widget (Fan → ON)
```

### **2. Morning Routine**
```
Name: Morning Lights
Trigger: Schedule (Daily at 07:00)
Action: Control Widget (Lights → ON)
```

### **3. Emergency Stop**
```
Name: Emergency Shutdown
Trigger: Manual
Action: Publish MQTT (emergency/stop → ALL)
```

### **4. Low Battery Alert**
```
Name: Battery Warning
Trigger: Widget (Battery < 20)
Action: Show Notification
```

### **5. Weekday Alarm**
```
Name: Work Alarm
Trigger: Schedule (Mon-Fri at 06:30)
Action: Control Widget (Alarm → RING)
```

---

## 🎨 Understanding Trigger Badges

In the rule list, you'll see colored badges:

- **🔵 WIDGET** - Triggered by sensor values
- **🟠 MANUAL** - Triggered by button click
- **🟣 SCHEDULE** - Triggered by time

---

## 🎛️ Managing Rules

### **Activate/Deactivate**
- Use the toggle switch on each rule card
- Inactive rules won't trigger

### **Manual Trigger**
- For manual rules, tap the green **"Trigger Now"** button
- Instant execution!

### **Edit Rule**
- Tap **"Edit"** button
- Modify any settings
- Tap **"Save"**

### **Delete Rule**
- Tap **"Delete"** button
- Confirm deletion

---

## 💡 Pro Tips

1. **Start Simple**: Begin with widget triggers before exploring schedules
2. **Test Manual First**: Create manual rules to test actions before automating
3. **Use Descriptive Names**: "Auto Fan at 30°C" is better than "Rule 1"
4. **Check Last Triggered**: Monitor rule activity in the rule card
5. **Combine Actions**: One rule can have multiple actions

---

## ❓ FAQ

**Q: How many rules can I create?**  
A: Unlimited! Create as many as you need.

**Q: Can one rule control multiple widgets?**  
A: Not directly, but you can create multiple "Control Widget" actions in one rule (future feature).

**Q: What happens if I delete a widget used in a rule?**  
A: The rule will show "[Widget not found]" but won't crash.

**Q: Can I export/import rules?**  
A: Not yet, but it's planned for future updates.

**Q: Do rules work when app is closed?**  
A: No, the app must be running for rules to execute.

---

## 🆘 Troubleshooting

**Rule not triggering?**
- ✅ Check if rule is active (toggle switch ON)
- ✅ Verify widget is publishing data
- ✅ Check threshold value is correct
- ✅ For schedules, verify time is correct

**Control widget not working?**
- ✅ Check target widget has a publish topic
- ✅ Verify payload is correct (ON/OFF for toggles)
- ✅ Check MQTT connection is active

**Notification not showing?**
- ✅ Grant notification permissions
- ✅ Check device notification settings

---

## 📚 Learn More

- **Full Documentation**: See `.agent/AUTOMATION_COMPLETE_SUMMARY.md`
- **Developer Guide**: See `.agent/AUTOMATION_QUICK_REFERENCE.md`
- **In-App Help**: Tap the (?) icon in Rule Manager

---

**Happy Automating! 🎉**
