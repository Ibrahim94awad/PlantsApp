package nl.plantenkwekerij.registratie.data

import android.content.Context
import androidx.room.*
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.flow.Flow
import java.io.BufferedReader

private fun now() = System.currentTimeMillis()

@Entity(tableName = "plants", indices = [Index(value = ["name"], unique = true)]) data class Plant(@PrimaryKey(autoGenerate = true) val id: Long = 0, val name: String, val createdAt: Long = now(), val updatedAt: Long = now())
@Entity(tableName = "departments", indices = [Index(value = ["name"], unique = true)]) data class Department(@PrimaryKey(autoGenerate = true) val id: Long = 0, val name: String, val createdAt: Long = now(), val updatedAt: Long = now())
@Entity(tableName = "lines", indices = [Index(value = ["name"]), Index(value = ["departmentId"])], foreignKeys = [ForeignKey(entity = Department::class, parentColumns = ["id"], childColumns = ["departmentId"], onDelete = ForeignKey.RESTRICT)]) data class Line(@PrimaryKey(autoGenerate = true) val id: Long = 0, val name: String, val departmentId: Long? = null, val createdAt: Long = now(), val updatedAt: Long = now())
@Entity(tableName = "sizes", indices = [Index(value = ["name"], unique = true)]) data class Size(@PrimaryKey(autoGenerate = true) val id: Long = 0, val name: String, val defaultQuantity: Int, val createdAt: Long = now(), val updatedAt: Long = now())
@Entity(tableName = "inventory_records", indices = [Index("plantId"), Index("departmentId"), Index("lineId"), Index("sizeId")], foreignKeys = [ForeignKey(entity = Plant::class,parentColumns=["id"],childColumns=["plantId"],onDelete=ForeignKey.RESTRICT), ForeignKey(entity=Department::class,parentColumns=["id"],childColumns=["departmentId"],onDelete=ForeignKey.RESTRICT), ForeignKey(entity=Line::class,parentColumns=["id"],childColumns=["lineId"],onDelete=ForeignKey.RESTRICT), ForeignKey(entity=Size::class,parentColumns=["id"],childColumns=["sizeId"],onDelete=ForeignKey.RESTRICT)]) data class InventoryRecord(@PrimaryKey(autoGenerate = true) val id: Long = 0, val plantId: Long, val departmentId: Long, val lineId: Long, val sizeId: Long, val quantity: Int, val createdAt: Long = now(), val updatedAt: Long = now())

data class InventoryRow(val id: Long, val plant: String, val department: String, val line: String, val size: String, val quantity: Int, val createdAt: Long, val updatedAt: Long)
data class InventoryFilter(val plantId: Long? = null, val departmentId: Long? = null, val lineId: Long? = null, val sizeId: Long? = null)

@Dao interface InventoryDao {
    @Query("""SELECT r.id, p.name plant, d.name department, l.name line, s.name size, r.quantity, r.createdAt, r.updatedAt FROM inventory_records r JOIN plants p ON p.id=r.plantId JOIN departments d ON d.id=r.departmentId JOIN lines l ON l.id=r.lineId JOIN sizes s ON s.id=r.sizeId WHERE (:search='' OR lower(p.name) LIKE '%' || lower(:search) || '%' OR lower(d.name) LIKE '%' || lower(:search) || '%' OR lower(l.name) LIKE '%' || lower(:search) || '%' OR lower(s.name) LIKE '%' || lower(:search) || '%') AND (:plantId IS NULL OR r.plantId=:plantId) AND (:departmentId IS NULL OR r.departmentId=:departmentId) AND (:lineId IS NULL OR r.lineId=:lineId) AND (:sizeId IS NULL OR r.sizeId=:sizeId) ORDER BY r.updatedAt DESC""") fun rows(search: String, plantId: Long?, departmentId: Long?, lineId: Long?, sizeId: Long?): Flow<List<InventoryRow>>
    @Query("SELECT * FROM inventory_records WHERE id=:id") suspend fun record(id: Long): InventoryRecord?
    @Insert suspend fun insert(record: InventoryRecord): Long
    @Update suspend fun update(record: InventoryRecord)
    @Delete suspend fun delete(record: InventoryRecord)
    @Query("SELECT COUNT(*) FROM inventory_records WHERE plantId=:id") suspend fun plantUsage(id:Long):Int
    @Query("SELECT COUNT(*) FROM inventory_records WHERE departmentId=:id OR lineId IN (SELECT id FROM lines WHERE departmentId=:id)") suspend fun departmentUsage(id:Long):Int
    @Query("SELECT COUNT(*) FROM inventory_records WHERE lineId=:id") suspend fun lineUsage(id:Long):Int
    @Query("SELECT COUNT(*) FROM inventory_records WHERE sizeId=:id") suspend fun sizeUsage(id:Long):Int
}
@Dao interface MasterDao {
    @Query("SELECT * FROM plants WHERE name LIKE '%' || :q || '%' COLLATE NOCASE ORDER BY name") fun plants(q:String=""):Flow<List<Plant>>; @Insert(onConflict=OnConflictStrategy.IGNORE) suspend fun addPlant(x:Plant):Long; @Update suspend fun updatePlant(x:Plant); @Delete suspend fun deletePlant(x:Plant)
    @Query("SELECT * FROM departments WHERE name LIKE '%' || :q || '%' COLLATE NOCASE ORDER BY name") fun departments(q:String=""):Flow<List<Department>>; @Insert(onConflict=OnConflictStrategy.IGNORE) suspend fun addDepartment(x:Department):Long; @Update suspend fun updateDepartment(x:Department); @Delete suspend fun deleteDepartment(x:Department)
    @Query("SELECT * FROM lines WHERE name LIKE '%' || :q || '%' COLLATE NOCASE AND (:departmentId IS NULL OR departmentId IS NULL OR departmentId=:departmentId) ORDER BY name") fun lines(q:String="",departmentId:Long?=null):Flow<List<Line>>; @Insert suspend fun addLine(x:Line):Long; @Update suspend fun updateLine(x:Line); @Delete suspend fun deleteLine(x:Line)
    @Query("SELECT * FROM sizes WHERE name LIKE '%' || :q || '%' COLLATE NOCASE ORDER BY name") fun sizes(q:String=""):Flow<List<Size>>; @Insert(onConflict=OnConflictStrategy.IGNORE) suspend fun addSize(x:Size):Long; @Update suspend fun updateSize(x:Size); @Delete suspend fun deleteSize(x:Size)
}
@Database(entities=[Plant::class,Department::class,Line::class,Size::class,InventoryRecord::class],version=2,exportSchema=true)
abstract class PlantDatabase:RoomDatabase(){ abstract fun inventory():InventoryDao; abstract fun master():MasterDao
 companion object { fun open(context:Context)=Room.databaseBuilder(context,PlantDatabase::class.java,"plantregistratie.db").addMigrations(object:Migration(1,2){override fun migrate(db:SupportSQLiteDatabase){db.execSQL("CREATE INDEX IF NOT EXISTS index_inventory_records_plantId ON inventory_records(plantId)")}}).addCallback(object:Callback(){override fun onCreate(db:SupportSQLiteDatabase){ super.onCreate(db)
     context.assets.open("plants.csv").bufferedReader().useLines { rows -> rows.drop(1).map(String::trim).filter(String::isNotEmpty).forEach { name -> db.execSQL("INSERT OR IGNORE INTO plants(name,createdAt,updatedAt) VALUES(?,?,?)", arrayOf(name.removeSurrounding("\""),now(),now())) } }
     context.assets.open("departments.txt").bufferedReader().useLines { it.map(String::trim).filter(String::isNotEmpty).forEach { name -> db.execSQL("INSERT OR IGNORE INTO departments(name,createdAt,updatedAt) VALUES(?,?,?)", arrayOf(name,now(),now())) } }
     (1..50).forEach { number -> db.execSQL("INSERT INTO lines(name,departmentId,createdAt,updatedAt) VALUES(?,?,?,?)", arrayOf("Lijn $number", null, now(), now())) }
     listOf("1L" to 250,"2L" to 150,"5L" to 80).forEach { (name,quantity) -> db.execSQL("INSERT OR IGNORE INTO sizes(name,defaultQuantity,createdAt,updatedAt) VALUES(?,?,?,?)",arrayOf(name,quantity,now(),now())) }
 } }).build() } }
