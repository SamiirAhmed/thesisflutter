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
    const ROLE_ADMIN        = 5;
    const ROLE_STUDENT      = 6;
    const ROLE_TEACHER      = 7;
    const ROLE_EXAM_OFFICER = 8;

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
        // role_name is loaded at login from the roles table
        return strtolower($this->role_name ?? '') === strtolower($role);
    }

    /**
     * Check a Sanctum ability on the current token.
     */
    public function hasPermission(string $permission): bool
    {
        if ($this->currentAccessToken() && $this->tokenCan($permission)) {
            return true;
        }
        return false;
    }
}
