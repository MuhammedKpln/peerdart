---
name: Bug report
about: Create a report to help us improve
title: 'Call connection issue when peers are outside the local network'
labels: bug
assignees: ''

---

**Describe the bug**
When users are in the same network, let's say on home wifi, the call process works great. Try to get one of them outside the local area, the call will not be established correctly.

**To Reproduce**
Steps to reproduce the behavior:
1. A and B are in different networks
2. A Makes a call for B
3. B answer the call.
4. Connection between A and B cannot be established
5. The call will close soon.

**Expected behavior**
When peer are in different networks, the connection between them should be established correctly.

**Smartphone (please complete the following information):**
 - Device: Google Pixel 6 and Samsung Galaxy S7
 - OS: Android 13 and Android 10
 - Peerdart version 0.5.0
