<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    protected $table = 'students';
    protected $primaryKey = 'std_id';

    protected $fillable = [
        'user_id',
        'student_id',
        'name',
        'tell',
        'gender',
        'email',
        'status',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }

    public function leader()
    {
        return $this->hasOne(ClassLeader::class, 'std_id', 'std_id');
    }

    public function memberships()
    {
        return $this->hasMany(StudentClass::class, 'std_id', 'std_id');
    }
}
