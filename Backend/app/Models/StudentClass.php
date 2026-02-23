<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentClass extends Model
{
    protected $table = 'studet_classes';
    protected $primaryKey = 'sc_no';

    protected $fillable = [
        'cls_no',
        'std_id',
        'sem_no',
        'acy_no',
    ];

    public function classroom()
    {
        return $this->belongsTo(Classroom::class, 'cls_no', 'cls_no');
    }

    public function student()
    {
        return $this->belongsTo(Student::class, 'std_id', 'std_id');
    }
}
