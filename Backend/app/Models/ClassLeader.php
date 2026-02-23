<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClassLeader extends Model
{
    protected $table = 'leaders';
    protected $primaryKey = 'lead_id';

    protected $fillable = [
        'cls_no',
        'std_id',
    ];

    public function student()
    {
        return $this->belongsTo(Student::class, 'std_id', 'std_id');
    }

    public function classroom()
    {
        return $this->belongsTo(Classroom::class, 'cls_no', 'cls_no');
    }

    public function complaints()
    {
        return $this->hasMany(ClassIssueComplaint::class, 'lead_id', 'lead_id');
    }
}
