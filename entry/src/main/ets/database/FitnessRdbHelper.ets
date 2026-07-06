/**
 * Fitness Tracking RDB Helper Module
 *
 * @description Provides relational database operations for fitness tracking wearable application.
 * Handles database initialization, CRUD operations, and data persistence using HarmonyOS RDB Store.
 *
 * @module FitnessRdbHelper
 * @requires @kit.ArkData - Relational database operations
 * @requires @kit.BasicServicesKit - Business error handling
 *
 * @author HarmonyOS Codelab
 * @version 1.0.0
 */

import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

/** Database file name for fitness tracking */
const DB_NAME: string = 'fitness_track.db';

/** Name of the workouts table in database */
const TABLE_WORKOUT: string = 'WORKOUTS';

/**
 * Represents a workout record stored in the database
 *
 * @interface WorkoutRecord
 * @property {number} id - Unique identifier for the workout (auto-incremented primary key)
 * @property {string} workoutType - Type of workout ("Run" or "Walk")
 * @property {number} durationMinutes - Duration of workout in minutes
 * @property {number} dateMillis - Timestamp of the workout in milliseconds since epoch
 * @property {number} distanceKm - Distance covered during workout in kilometers
 */
export interface WorkoutRecord {
  id: number;
  workoutType: string;
  durationMinutes: number;
  dateMillis: number;
  distanceKm: number;
}

/**
 * RDB Helper Class for Fitness Tracking Operations
 *
 * @class FitnessRdbHelper
 * @description Manages all database operations including:
 * - Database initialization and table creation
 * - Inserting random mock workout data
 * - Querying all workout records
 * - Clearing all workout data
 *
 * @example
* ```ts
 * const helper = new FitnessRdbHelper();
 * const rdbStore = await helper.initRdb(context);
 * const workouts = await helper.getAllWorkouts();
 * ```
 */
export class FitnessRdbHelper {
  /** RDB Store instance for database operations */
  private rdbStore: relationalStore.RdbStore | null = null;

  /**
   * Initializes the RDB database
   *
   * @async
   * @param {Context} context - HarmonyOS application context
   * @returns {Promise<relationalStore.RdbStore>} Initialized RDB store instance
   * @throws {Error} When database initialization fails
   *
   * @description Performs the following operations:
   * 1. Creates database configuration with security level S1
   * 2. Opens/Creates the database file
   * 3. Creates necessary tables if they don't exist
   *
   * @example
  * ```ts
   * const store = await helper.initRdb(getContext(this));
   * ```
   */
  async initRdb(context: Context): Promise<relationalStore.RdbStore> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.createTables();
      return this.rdbStore;
    } catch (err) {
      const error = err as BusinessError;
      throw new Error(`Failed to init DB: ${error.message}`);
    }
  }

  /**
   * Creates the workouts table if it doesn't exist
   *
   * @private
   * @async
   * @returns {Promise<void>}
   * @throws {Error} When SQL execution fails
   *
   * @description Table schema:
   * - id: Auto-incrementing primary key
   * - workout_type: TEXT - Type of workout (Run/Walk)
   * - duration_minutes: INTEGER - Duration in minutes
   * - date_millis: INTEGER - Unix timestamp in milliseconds
   * - distance_km: REAL - Distance in kilometers
   */
  private async createTables(): Promise<void> {
    const sqlWorkout: string = `CREATE TABLE IF NOT EXISTS ${TABLE_WORKOUT} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      workout_type TEXT NOT NULL,
      duration_minutes INTEGER NOT NULL,
      date_millis INTEGER NOT NULL,
      distance_km REAL
    )`;
    await this.rdbStore!.executeSql(sqlWorkout);
  }

  /**
   * Generates and inserts a random mock workout into the database
   *
   * @async
   * @returns {Promise<number>} The auto-generated ID of the inserted workout
   * @throws {Error} When insert operation fails
   *
   * @description Random data generation rules:
   * - Workout type: Randomly "Run" or "Walk"
   * - Duration: Run (20-60 min), Walk (25-60 min)
   * - Distance: Run (2-10 km), Walk (1-5 km)
   * - Date: Random day within last 7 days
   *
   * @example
  * ```ts
   * const newWorkoutId = await helper.insertRandomWorkout();
   * console.log(`Inserted workout with ID: ${newWorkoutId}`);
   * ```
   */
  async insertRandomWorkout(): Promise<number> {
    const types: string[] = ['Run', 'Walk'];
    const now: number = Date.now();

    const randomType: string = types[now % types.length];
    const duration: number = randomType === 'Run'
      ? 20 + (Math.floor(now / 10) % 40)   // Run: 20-60 minutes
      : 25 + (Math.floor(now / 10) % 35);  // Walk: 25-60 minutes

    const distanceTenths: number = Math.floor(now / 3) % 80;
    const distance: number = randomType === 'Run'
      ? parseFloat((2 + distanceTenths / 10).toFixed(1))           // Run: 2.0-9.9 km
      : parseFloat((1 + (distanceTenths % 40) / 10).toFixed(1));   // Walk: 1.0-4.9 km

    const date: number = now - ((Math.floor(now / 100) % 7) * 24 * 60 * 60 * 1000);

    const bucket: relationalStore.ValuesBucket = {
      workout_type: randomType,
      duration_minutes: duration,
      date_millis: date,
      distance_km: distance
    };

    const id: number = await this.rdbStore!.insert(TABLE_WORKOUT, bucket);
    return id;
  }

  /**
   * Retrieves all workout records from the database
   *
   * @async
   * @returns {Promise<WorkoutRecord[]>} Array of all workout records ordered by ID ascending
   * @throws {Error} When query operation fails
   *
   * @description
  * - Queries all rows from WORKOUTS table
   * - Orders results by ID in ascending order (oldest first)
   * - Closes ResultSet automatically after processing
   *
   * @example
  * ```ts
   * const workouts = await helper.getAllWorkouts();
   * console.log(`Found ${workouts.length} workouts`);
   * workouts.forEach(workout => {
   *   console.log(`${workout.workoutType}: ${workout.distanceKm}km`);
   * });
   * ```
   */
  async getAllWorkouts(): Promise<WorkoutRecord[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_WORKOUT);
    predicates.orderByAsc('id');

    const resultSet: relationalStore.ResultSet = await this.rdbStore!.query(predicates);
    const workouts: WorkoutRecord[] = [];

    while (resultSet.goToNextRow()) {
      const workout: WorkoutRecord = {
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        workoutType: resultSet.getString(resultSet.getColumnIndex('workout_type')),
        durationMinutes: resultSet.getLong(resultSet.getColumnIndex('duration_minutes')),
        dateMillis: resultSet.getLong(resultSet.getColumnIndex('date_millis')),
        distanceKm: resultSet.getDouble(resultSet.getColumnIndex('distance_km'))
      };
      workouts.push(workout);
    }

    // Always close ResultSet to free resources
    resultSet.close();
    return workouts;
  }

  /**
   * Deletes all workout records from the database
   *
   * @async
   * @returns {Promise<void>}
   * @throws {Error} When delete operation fails
   *
   * @description
  * - Uses RdbPredicates without conditions to target all rows
   * - Permanently removes all data from WORKOUTS table
   * - Operation cannot be undone (irreversible)
   *
   * @warning This operation is permanent and cannot be rolled back
   *
   * @example
  * ```ts
   * await helper.clearAllWorkouts();
   * console.log('All workout data has been cleared');
   * ```
   */
  async clearAllWorkouts(): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_WORKOUT);
    await this.rdbStore!.delete(predicates);
  }
}