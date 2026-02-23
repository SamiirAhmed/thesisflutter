<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Classroom extends Model
{
    protected $table = 'classes';
    protected $primaryKey = 'cls_no';

    protected $fillable = [
        'cl_name',
        'dept_no',
        'camp_no',
    ];

    public function leader()
    {
        return $this->hasOne(ClassLeader::class, 'cls_no', 'cls_no');
    }
}
