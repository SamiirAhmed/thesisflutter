<?php

namespace App\Models\campus_env;

use Illuminate\Database\Eloquent\Model;
use App\Models\Student;

class CampusEnvSupport extends Model
{
    protected $table = 'campus_env_support';
    protected $primaryKey = 'ces_no';

    protected $fillable = [
        'cmp_env_com_no',
        'std_id',
        'supported_at',
    ];

    public function complaint()
    {
        return $this->belongsTo(CampusEnvComplaint::class, 'cmp_env_com_no', 'cmp_env_com_no');
    }

    public function student()
    {
        return $this->belongsTo(Student::class, 'std_id', 'std_id');
    }
}
