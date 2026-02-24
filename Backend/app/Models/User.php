<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Notifications\Notifiable;

/**
 * User model — maps to the existing `users` table in thesessystem.
 *
 * Important: The table exists. Do NOT create migrations.
 * Column names come from the existing schema.
 *
 * Role IDs (from DB):
 *   6 = Student
 *   7 = Teacher
 *   5 = Admin
 *   8 = ExamOfficer
 */
class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    // ── Table config ──────────────────────────────────────────────────────────
    protected $table      = 'users';
    protected $primaryKey = 'user_id';
    public    $incrementing = true;
    protected $keyType    = 'int';

    // ── Modifiable columns ────────────────────────────────────────────────────
    protected $fillable = [
        'user_id',
        'role_id',
        'full_name',
        'username',
        'phone',
        'email',
        'status',
        'Accees_channel',      // stored in DB with this spelling
    ];

    protected $hidden = [
        'password_hash',       // column name in existing DB
    ];

    protected function casts(): array
    {
        return [];
    }

    // ── Role constants (from database) ───────────────────────────────────────
    const ROLE_STUDENT      = 1;
    const ROLE_TEACHER      = 2;
    const ROLE_EXAM_OFFICER = 3;
    const ROLE_ADMIN        = 4;

    // ── Helpers ───────────────────────────────────────────────────────────────

    public function isStudent(): bool
    {
        return (int) $this->role_id === self::ROLE_STUDENT;
    }

    public function isTeacher(): bool
    {
        return (int) $this->role_id === self::ROLE_TEACHER;
    }

    /**
     * Check role by name (case-insensitive).
     */
    public function hasRole(string $role): bool
    {
        if (!isset($this->role_name)) {
            $this->role_name = \Illuminate\Support\Facades\DB::table('roles')
                ->where('role_id', $this->role_id)
                ->value('role_name');
        }
        return strtolower($this->role_name ?? '') === strtolower($role);
    }

    public function student()
    {
        return $this->hasOne(Student::class, 'user_id', 'user_id');
    }

    /**
     * Check if the user is a Class Leader.
     */
    public function isLeader(): bool
    {
        return \Illuminate\Support\Facades\DB::table('leaders')
            ->join('students', 'leaders.std_id', '=', 'students.std_id')
            ->where('students.user_id', $this->user_id)
            ->exists();
    }

    /**
     * Get the Class Leader record for this user.
     */
    public function getLeaderRecord()
    {
        $student = $this->student;
        if (!$student) return null;

        return \App\Models\ClassLeader::where('std_id', $student->std_id)->first();
    }
}
