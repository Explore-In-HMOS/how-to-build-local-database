/**
 * Fitness Tracking Wearable Application
 *
 * @description A HarmonyOS Next wearable application that demonstrates RDB (Relational Database) operations
 * including insert, query, delete, and transaction management. The app generates mock workout data
 * and displays it in an ArcList component optimized for circular screen wearables.
 *
 * @module Index
 * @requires @kit.ArkUI - UI components including ArcList for circular wearable displays
 * @requires @kit.ArkData - RDB (Relational Database) operations
 *
 * @author HarmonyOS Codelab
 * @version 1.0.0
 */

import {
  ArcList,
  ArcListItem,
  ArcListAttribute,
  ArcListItemAttribute,
  LengthMetrics,
  promptAction
} from '@kit.ArkUI';

import { FitnessRdbHelper } from '../database/FitnessRdbHelper';
import { relationalStore } from '@kit.ArkData';

/**
 * Represents a workout record stored in the database
 *
 * @interface WorkoutRecord
 * @property {number} id - Unique identifier for the workout (auto-incremented)
 * @property {string} workoutType - Type of workout ("Run" or "Walk")
 * @property {number} durationMinutes - Duration of workout in minutes
 * @property {number} dateMillis - Timestamp of the workout in milliseconds
 * @property {number} distanceKm - Distance covered during workout in kilometers
 * @property {number} [avgHeartRate] - Optional average heart rate during workout
 */
interface WorkoutRecord {
  id: number;
  workoutType: string;
  durationMinutes: number;
  dateMillis: number;
  distanceKm: number;
  avgHeartRate?: number;
}

/**
 * Main application component for Fitness Tracking Wearable
 *
 * @component
 * @description This component manages the workout tracking interface including:
 * - Database initialization and data persistence
 * - Displaying workout history in ArcList (circular screen optimized)
 * - Adding new mock workout data
 * - Clearing all workout data
 * - Real-time UI updates with loading states
 *
 * @example
* ```ts
 * // Component automatically renders when imported
 * <Index />
 * ```
 */
@Entry
@Component
struct Index {
  /** Indicates whether initial data is being loaded from database */
  @State isLoading: boolean = true;

  /** Indicates whether a data operation (add/clear) is in progress */
  @State isRefreshing: boolean = false;

  /** Array of workout records fetched from database */
  @State workoutList: WorkoutRecord[] = [];

  /** Helper class instance for database operations */
  private rdbHelper: FitnessRdbHelper = new FitnessRdbHelper();

  /** Reference to the RDB store instance */
  private rdbStore: relationalStore.RdbStore | null = null;

  /** Scroller controller for programmatic scrolling in ArcList */
  private scroller: Scroller = new Scroller();

  /**
   * Lifecycle callback - Called when component is about to appear on screen
   *
   * @async
   * @returns {Promise<void>}
   * @description Triggers initial data loading from database
   */
  async aboutToAppear(): Promise<void> {
    await this.loadData();
  }

  /**
   * Loads workout data from database
   *
   * @async
   * @returns {Promise<void>}
   * @description Initializes RDB connection and fetches all workout records
   * @throws {Error} If database initialization or query fails
   */
  async loadData(): Promise<void> {
    try {
      this.isLoading = true;
      this.rdbStore = await this.rdbHelper.initRdb(this.getUIContext().getHostContext()!);
      await this.fetchAllWorkouts();

      this.isLoading = false;
    } catch (err) {
      this.isLoading = false;
      console.error('Load Error: ', JSON.stringify(err));
      promptAction.showToast({
        message: $r('app.string.error_db'),
        duration: 2000
      });
    }
  }

  /**
   * Fetches all workout records from database
   *
   * @async
   * @returns {Promise<void>}
   * @description Retrieves all workouts from RDB and updates the workoutList state
   * @throws {Error} If database query operation fails
   */
  async fetchAllWorkouts(): Promise<void> {
    try {
      const workouts = await this.rdbHelper.getAllWorkouts();
      this.workoutList = workouts;
    } catch (err) {
      console.error('Fetch Error: ', JSON.stringify(err));
      this.workoutList = [];
    }
  }

  /**
   * Adds a new randomly generated mock workout to the database
   *
   * @async
   * @returns {Promise<void>}
   * @description
  * - Generates random workout data (type, duration, distance)
   * - Inserts into RDB database
   * - Refreshes the displayed list
   * - Auto-scrolls to the newly added item
   *
   * @throws {Error} If insert operation fails
   */
  async addNewMockWorkout(): Promise<void> {
    try {
      this.isRefreshing = true;
      await this.rdbHelper.insertRandomWorkout();
      await this.fetchAllWorkouts();

      this.isRefreshing = false;

      promptAction.showToast({
        message: $r('app.string.data_added'),
        duration: 1500
      });

      // Auto-scroll to the newly added workout (last item)
      if (this.workoutList.length > 0) {
        this.scroller.scrollToIndex(this.workoutList.length - 1);
      }
    } catch (err) {
      this.isRefreshing = false;
      console.error('Insert Error: ', JSON.stringify(err));
      promptAction.showToast({
        message: $r('app.string.error_add'),
        duration: 2000
      });
    }
  }

  /**
   * Deletes all workout records from the database
   *
   * @async
   * @returns {Promise<void>}
   * @description
  * - Clears all data from WORKOUTS table
   * - Resets the workoutList state to empty array
   * - Shows confirmation toast message
   *
   * @warning This operation is irreversible
   * @throws {Error} If delete operation fails
   */
  async clearAllData(): Promise<void> {
    try {
      this.isRefreshing = true;

      await this.rdbHelper.clearAllWorkouts();
      this.workoutList = [];

      this.isRefreshing = false;

      promptAction.showToast({
        message: $r('app.string.data_cleared'),
        duration: 1500
      });
    } catch (err) {
      this.isRefreshing = false;
      console.error('Clear Error: ', JSON.stringify(err));
      promptAction.showToast({
        message: $r('app.string.error_clear'),
        duration: 2000
      });
    }
  }

  /**
   * Formats a timestamp into a readable date string
   *
   * @param {number} timestamp - Unix timestamp in milliseconds
   * @returns {string} Formatted date string in DD/MM/YYYY format
   *
   * @example
  * formatDate(1704067200000) // Returns "01/01/2024"
   */
  formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()}`;
  }

  /**
   * Renders the main UI component
   *
   * @returns {void}
   * @description Builds the UI with three main states:
   * - Loading state: Shows loading spinner
   * - Empty state: Shows empty list message with add button
   * - Data state: Displays ArcList with workout history and action buttons
   */
  build() {
    Column() {
      if (this.isLoading) {
        this.LoadingView();
      } else if (this.workoutList.length === 0) {
        this.EmptyStateView();
      } else {
        this.DataView();
      }

      if (this.isRefreshing) {
        this.RefreshingIndicator();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_background'))
  }

  /**
   * Loading state view component
   *
   * @builder
   * @description Displays a loading spinner and text while initial data is being fetched
   */
  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color($r('app.color.color_primary'))
      Text($r('app.string.loading_data'))
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  /**
   * Empty state view component
   *
   * @builder
   * @description Displays when no workout records exist, showing:
   * - Empty folder icon
   * - "No workouts yet" message
   * - Button to add first workout
   */
  @Builder
  EmptyStateView() {
    Column() {
      Text('📭')
        .fontSize(48)
        .margin({ bottom: 16 })
      Text($r('app.string.no_data'))
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
      Button($r('app.string.add_first_workout'))
        .fontSize(12)
        .height(36)
        .backgroundColor($r('app.color.color_primary'))
        .borderRadius(18)
        .margin({ top: 20 })
        .onClick(() => {
          this.addNewMockWorkout();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  /**
   * Data view component with ArcList
   *
   * @builder
   * @description Main view displaying:
   * - ArcList with workout history (optimized for circular screens)
   * - Header with workout count
   * - Individual workout cards
   * - Action buttons (Add + Clear) in toolbar
   *
   * @features
  * - ArcList with circular screen optimization
   * - Smooth animations with chainAnimation
   * - Digital crown support for navigation
   * - Auto-hiding scrollbar
   */
  @Builder
  DataView() {
    ArcList({ scroller: this.scroller }) {
      // Header section
      ArcListItem() {
        this.ListHeader()
      }

      // Workout items
      ForEach(this.workoutList, (item: WorkoutRecord, index: number) => {
        ArcListItem() {
          this.WorkoutCard(item)
        }
      }, (item: WorkoutRecord, index: number) => item.id.toString())

      // Toolbar with action buttons (Add + Clear)
      ArcListItem(){
        this.ActionBar()
      }
    }
    .width('100%')
    .height('100%')
    .space(LengthMetrics.vp(12))
    .scrollBar(BarState.Auto)
    .chainAnimation(true)
    .fadingEdge(true)
    .digitalCrownSensitivity(CrownSensitivity.MEDIUM)
    .onScrollIndex((firstIndex: number, lastIndex: number, centerIndex: number) => {
      console.info(`Scroll Index - Center: ${centerIndex}`);
    })
  }

  /**
   * Action bar component with add and clear buttons
   *
   * @builder
   * @description Displays a toolbar containing:
   * - Page title ("Workout History")
   * - Add button (+ Add) to insert new mock workout
   * - Clear button (🗑️) to delete all workouts
   */
  @Builder
  ActionBar() {
    Row() {
      Text($r('app.string.page_title'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.color_text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Start)

      // Add new workout button
      Button() {
        Row() {
          Text('➕').fontSize(16)
          Text($r('app.string.add_workout')).fontSize(12).margin({ left: 4 })
        }
        .padding({ left: 8, right: 8 })
      }
      .height(32)
      .backgroundColor($r('app.color.color_primary'))
      .borderRadius(16)
      .onClick(() => {
        this.addNewMockWorkout();
      })

      // Clear all data button
      Button() {
        Row() {
          Text('🗑️').fontSize(16)
        }
        .padding({ left: 8, right: 8 })
      }
      .height(32)
      .margin({ left: 8 })
      .backgroundColor($r('app.color.color_accent'))
      .borderRadius(16)
      .onClick(() => {
        this.clearAllData();
      })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 8 })
    .backgroundColor($r('app.color.color_background'))
  }

  /**
   * List header component
   *
   * @builder
   * @description Displays a header section with:
   * - Running emoji icon (🏃‍♂️)
   * - "Workout History" title
   * - Total count of workouts in parentheses
   */
  @Builder
  ListHeader() {
    Row() {
      Text('🏃‍♂️')
        .fontSize(16)
        .margin({ right: 8 })
      Text($r('app.string.workout_history'))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_primary'))
      Text(` (${this.workoutList.length})`)
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
    }
    .padding(12)
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  /**
   * Individual workout card component
   *
   * @builder
   * @param {WorkoutRecord} item - The workout record to display
   * @description Displays a card with:
   * - Workout type icon (🏃 for Run, 🚶 for Walk)
   * - Workout type name and formatted date
   * - Duration (minutes) with ⏱️ icon
   * - Distance (kilometers) with 📍 icon
   * - Click handler showing workout details in toast
   *
   * @interactions
  * - Touch/Focus support for wearable devices
   * - Click shows full workout details via toast
   */
  @Builder
  WorkoutCard(item: WorkoutRecord) {
    Row() {
      // Icon column
      Column() {
        Text(item.workoutType === 'Run' ? '🏃' : '🚶')
          .fontSize(28)
      }
      .width(50)
      .alignItems(HorizontalAlign.Center)

      // Content column
      Column() {
        // Type and date row
        Row() {
          Text(item.workoutType)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.color_text_primary'))
          Text(this.formatDate(item.dateMillis))
            .fontSize(10)
            .fontColor($r('app.color.color_text_secondary'))
            .margin({ left: 8 })
        }
        .width('100%')

        // Duration and distance row
        Row() {
          // Duration
          Row() {
            Text('⏱️').fontSize(10)
            Text(`${item.durationMinutes} dk`)
              .fontSize(11)
              .fontColor($r('app.color.color_text_secondary'))
              .margin({ left: 2 })
          }
          .margin({ right: 12 })

          // Distance
          Row() {
            Text('📍').fontSize(10)
            Text(`${item.distanceKm} km`)
              .fontSize(11)
              .fontColor($r('app.color.color_text_secondary'))
              .margin({ left: 2 })
          }
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .backgroundColor($r('app.color.color_surface'))
    .borderRadius(16)
    .padding(12)
    .margin({ bottom: 4 })
    .onClick(() => {
      promptAction.showToast({
        message: `${item.workoutType}: ${item.durationMinutes} min, ${item.distanceKm} km`,
        duration: 1500
      });
    })
    .focusable(true)
    .focusOnTouch(true)
  }

  /**
   * Refreshing indicator component
   *
   * @builder
   * @description Shows a semi-transparent overlay with loading spinner and text
   * while data operations (add/clear) are in progress
   */
  @Builder
  RefreshingIndicator() {
    Row() {
      LoadingProgress()
        .width(24)
        .height(24)
        .color($r('app.color.color_primary'))
      Text($r('app.string.refreshing'))
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
        .margin({ left: 8 })
    }
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#33000000')
  }
}