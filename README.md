# Idee

Eine Art Brotato Vampire Survivors mit 2D-Grafik:
man läuft rum, killt Mobs und erhält XP
das Ziel ist mehrer und stärkere Gegner, da man mehr XP und Loot sammelt
gegner kommen aus Spawnern, die getroffen werden können
wenn Spawnern genug Schaden zugefügt wird, steigen sie in Level auf. sie werden entweder stärker oder es spawnen mehr und stärkere Gegner mit mehr Loot

man sammelt XP und levelt up:

bei jedem Levelup erscheint ein Levelup-Screen
  - in dem Screen kann man aus verschiedenen Upgrades für Waffen wählen
  - Beispiele für Upgrades:
    - +x Basisschaden
    - *y Schadenmultiplikator (z.B. basisschaden * 2 oder *1.5)
    - + Feuerrate
    - + HP
    - + XP Multiplikator

Es gibt Bäume, die man auch töten kann:
diese geben ebenfalls XP und Lebenspunkte (HP)



# Godot 4: Collision Layer vs. Collision Mask

Eine einfache Eselsbrücke, um **Layer** und **Mask** nie wieder zu verwechseln:

* **Layer ("Was bin ich?"):**  
  Die eigene Identität des Objekts. Es sagt der Physik-Engine, in welche Kategorie dieses Objekt gehört.
* **Mask ("Wonach suche ich?"):**  
  Die "Brille" des Objekts. Es bestimmt, welche *Layer* dieses Objekt wahrnimmt und womit es kollidieren oder interagieren soll.

> **Grundregel:** Eine Kollision findet statt, wenn **mindestens eine Seite** in ihrer *Mask* den *Layer* der anderen Seite aktiviert hat.

---

## Beispiel-Setup (Survivor / Horde-Game)

Eine empfohlene Aufteilung der Physik-Ebenen:

* **Layer 1:** Welt / Hindernisse (Wände, Bäume)
* **Layer 2:** Player
* **Layer 3:** Gegner (Slimes, Mobs)
* **Layer 4:** Pickups (Äpfel, Coins, XP)

### Objektspezifische Einstellungen

#### 1. Player
* **Layer:** `2` *(Ich bin der Spieler)*
* **Mask:** `1, 3, 4` *(Ich stoße gegen Wände [1], werde von Gegnern [3] getroffen und spüre Pickups [4])*

#### 2. Enemies (Gegner)
* **Layer:** `3` *(Ich bin ein Gegner)*
* **Mask:** `1, 2` *(Ich laufe gegen Wände [1] und verfolge/treffe den Spieler [2])*

#### 3. Pickups (Äpfel, Coins, Items)
* **Layer:** `4` *(Ich bin ein Pickup)*
* **Mask:** *keine (leer)* *(Ein rumliegendes Item muss selbst nicht aktiv die Welt scannen oder gegen Wände stoßen – es liegt einfach nur da)*

---

## Häufiger Fehler bei Pickups

Wenn ein Pickup **Layer 1** und **Mask 1** hat, verhält es sich wie eine solide Wand. Der Spieler bleibt daran hängen, anstatt einfach darüberzulaufen und es einzusammeln.

---

## Projekt-Tipp: Ebenen benennen

Damit im Inspektor echte Namen statt Zahlen stehen:

1. Öffne **Projekt > Projekteinstellungen**.
2. Navigiere zu **Layer-Namen > 2D-Physik**.
3. Vergib Namen für Layer 1–4 (`World`, `Player`, `Enemies`, `Pickups`).

--------

# Godot 4: Kollisions-Matrix für Player, Waffe & Objekte

Diese Übersicht dokumentiert die Layer- und Mask-Verteilung für das Kampf-, Ziel- und Kollisionssystem.

---

## 1. Ebenen-Definition (`Projekt > Projekteinstellungen > Layer-Namen > 2D-Physik`)

| Layer ID | Name | Beschreibung |
| :--- | :--- | :--- |
| **Layer 1** | `World_Trees` | Feste Umwelt-Objekte (Bäume, Wände, Felsen) |
| **Layer 2** | `Player` | Der Hauptcharakter |
| **Layer 3** | `Enemies` | Mobs, Slimes und gegnerische Einheiten |
| **Layer 4** | `Pickups` | Collectibles auf dem Boden (Äpfel, Coins, XP) |
| **Layer 5** | `Bullets` | Eigene Projektile und Schüsse |

---

## 2. Objekt-Konfiguration (Layer & Mask)

### 🌳 Tree (Baum / Hindernis)
Steht als solides Hindernis in der Welt.
* **Layer:** `1` *(World_Trees)*
* **Mask:** *keine (leer)*

### 👾 Enemy (Gegner)
Verfolgt den Spieler und kollidiert mit der Welt.
* **Layer:** `3` *(Enemies)*
* **Mask:** `1, 2, 3` *(Kollidiert mit Bäumen [1], Spieler [2] und anderen Gegnern [3])*

### 🧍 Player (Spieler)
Wird von der Umwelt und Gegnern geblockt.
* **Layer:** `2` *(Player)*
* **Mask:** `1, 3` *(Stößt an Bäume [1] und Gegner [3])*

### 🔫 Gun (Ziel-Scanner / Area2D)
Sucht aktiv nach Zielen in Reichweite. Ist selbst kein physikalischer Körper.
* **Layer:** *keine (leer)*
* **Mask:** `1, 3` *(Erkennt Bäume [1] und Gegner [3] zum Anvisieren)*

### 💥 Bullet (Projektil / Area2D oder RigidBody2D)
Trifft Ziele in der Welt.
* **Layer:** `5` *(Bullets)*
* **Mask:** `1, 3` *(Trifft Bäume [1] und Gegner [3], ignoriert den Spieler)*

### 🍎 Pickup (Loot / Items)
Liegt passiv auf der Karte.
* **Layer:** `4` *(Pickups)*
* **Mask:** *keine (leer)*

---

## 💡 Funktionsweise des Zielsystems

Damit die **Gun** (oder das `Area2D`-Skript der Waffe) Gegner und Bäume erkennt, muss in ihrer **Mask** sowohl **Layer 1** als auch **Layer 3** aktiviert sein.

Functions wie `get_overlapping_bodies()` oder das Signal `body_entered` reagieren **ausschließlich** auf Objekte, deren *Layer* in der *Mask* des Scanners enthalten sind.